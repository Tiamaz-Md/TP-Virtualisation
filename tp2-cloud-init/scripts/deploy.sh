#!/usr/bin/env bash
# deploy.sh — TP2 : déployer sur KVM/libvirt les VM décrites par l'inventaire,
# à partir des configurations générées dans output/ (user-data, meta-data, seed ISO).
#
# Workflow : inventaire + profils + templates Jinja2 -> generate.py -> deploy.sh -> KVM
#
# Usage :
#   ./deploy.sh [--inventory inventaire/vms.yaml] [--only NOM] [--dry-run]
#
# Prérequis : image de base généralisée (BASE_IMG, défaut /var/lib/libvirt/images/base-cloud.qcow2),
#             genisoimage + virt-install, scripts/generate.py exécuté (ou exécuté automatiquement ici).
set -euo pipefail

INV="inventaire/vms.yaml"
ONLY=""
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --inventory) INV="$2"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "Option inconnue : $1"; exit 1 ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BASE_IMG="${BASE_IMG:-/var/lib/libvirt/images/base-cloud.qcow2}"
IMGDIR="${IMGDIR:-/var/lib/libvirt/images}"
VIRSH="sudo virsh -c qemu:///system"
PYTHON="$(command -v python3 || echo python3)"

[ -f "$BASE_IMG" ] || { echo "Image de base introuvable : $BASE_IMG"; exit 1; }
[ -d "$ROOT/.venv" ] && PYTHON="$ROOT/.venv/bin/python"

# Les seeds doivent exister : on les (re)génère si absent (même inventaire)
for f in $(PYTHON="$PYTHON" python3 - "$INV" <<'PY'
import sys, yaml
inv = yaml.safe_load(open(sys.argv[1]).read())
print(" ".join(v["name"] for v in inv["vms"]))
PY
); do
  if [ ! -f "output/seed-$f.iso" ]; then
    echo ">> seed de '$f' absente : exécution de generate.py"
    "$PYTHON" scripts/generate.py --inventory "$INV"
    break
  fi
done

# Déploiement : pour chaque VM de l'inventaire (nom, cpu, ram, os)
"$PYTHON" - "$INV" <<'PY' | while IFS='|' read -r NAME CPU RAM OS; do
import sys, yaml
inv = yaml.safe_load(open(sys.argv[1]).read())
for v in inv["vms"]:
    print(f"{v['name']}|{v.get('cpu',2)}|{v.get('ram',2048)}|{v.get('os','ubuntu24.04')}")
PY
  [ -n "$ONLY" ] && [ "$NAME" != "$ONLY" ] && continue

  if $VIRSH dominfo "$NAME" >/dev/null 2>&1; then
    echo "== $NAME : déjà déployée, ignorée (utiliser --only après suppression pour redéployer)"
    continue
  fi
  SEED="$ROOT/output/seed-$NAME.iso"
  DISK="$IMGDIR/$NAME.qcow2"
  [ -f "$SEED" ] || { echo "== $NAME : seed absente ($SEED)"; continue; }
  [ -e "$DISK" ] && { echo "== $NAME : disque existant ($DISK), refus d'écraser"; continue; }

  echo "== $NAME : copie indépendante de l'image de base + virt-install --import ($CPU vCPU / ${RAM}Mio)"
  if [ "$DRY_RUN" = "1" ]; then
    echo "   sudo cp $BASE_IMG $DISK"
    echo "   sudo cp $SEED $IMGDIR/seed-$NAME.iso   # ISO accessible à libvirt-qemu (attention du sujet)"
    echo "   sudo virt-install --name $NAME --memory $RAM --vcpus $CPU --import --disk $DISK --disk $IMGDIR/seed-$NAME.iso --os-variant $OS --network network=default,model=virtio --graphics none --noautoconsole"
    continue
  fi
  sudo cp "$BASE_IMG" "$DISK"
  # L'ISO seed doit être lisible par libvirt-qemu : copie dans IMGDIR (attention du sujet TP2)
  sudo cp "$SEED" "$IMGDIR/seed-$NAME.iso" && sudo chmod 644 "$IMGDIR/seed-$NAME.iso"
  sudo virt-install --connect qemu:///system \
    --name "$NAME" --memory "$RAM" --vcpus "$CPU" \
    --disk path="$DISK",format=qcow2,bus=virtio \
    --disk path="$IMGDIR/seed-$NAME.iso",device=cdrom,readonly=on \
    --network network=default,model=virtio \
    --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    --import --os-variant "$OS" --graphics none --noautoconsole
  sleep 45
  # IP : agent invité d'abord, puis bail DHCP (avec attente)
  ip=""
  for _ in $(seq 1 40); do
    ip=$($VIRSH domifaddr "$NAME" --source agent 2>/dev/null \
         | awk '/ipv4/ && $4 !~ /^127\./ {print $4}' | cut -d/ -f1 | head -1)
    [ -n "$ip" ] || ip=$($VIRSH domifaddr "$NAME" --source lease 2>/dev/null \
         | awk '/ipv4/ {print $4}' | cut -d/ -f1 | head -1)
    [ -n "$ip" ] && break
    sleep 5
  done
  echo "   $NAME démarrée — IP : ${ip:-en attente}"
done

echo ">> Terminé. $VIRSH list --all"
