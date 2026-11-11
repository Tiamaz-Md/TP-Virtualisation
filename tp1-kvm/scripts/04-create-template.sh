#!/usr/bin/env bash
# 04-create-template.sh — TP1 Parties D et E (Exercices 7 et 9) :
#   capturer une copie de l'image installée puis généraliser cette COPIE en template
# Usage : ./04-create-template.sh <vm-source> [nom-template]
# Pré-requis dans la VM source (avant arrêt) : cloud-init clean --logs --seed ; sudo poweroff
set -euo pipefail

SRC="${1:?vm source requise}"
TEMPLATE="${2:-ubuntu-template-v1.qcow2}"
IMGDIR="${IMGDIR:-/var/lib/libvirt/images}"
VIRSH="sudo virsh -c qemu:///system"

$VIRSH shutdown "$SRC" 2>/dev/null || true
for _ in $(seq 1 60); do
  [ "$($VIRSH domstate "$SRC" | tr -d '\n')" = "shut off" ] && break
  sleep 2
done
[ "$($VIRSH domstate "$SRC" | tr -d '\n')" = "shut off" ] || { echo "La VM source tourne encore"; exit 1; }

# 1) Capture : convertir le disque (jamais sur un disque en cours d'utilisation)
sudo qemu-img convert -p -f qcow2 -O qcow2 "$IMGDIR/$SRC.qcow2" "$IMGDIR/$TEMPLATE"
sudo qemu-img check -f qcow2 "$IMGDIR/$TEMPLATE"
sudo sha256sum "$IMGDIR/$TEMPLATE" | tee "$TEMPLATE.sha256"

# 2) Généralisation de la COPIE (jamais de l'original) : identités retirées pour régénération
sudo virt-sysprep --list-operations | tr ',' '\n' | grep -E 'machine-id|ssh-hostkeys' >/dev/null
sudo virt-sysprep -a "$IMGDIR/$TEMPLATE" \
  --operations machine-id,ssh-hostkeys,udev-persistent-net,logfiles,tmp-files,bash-history
# Correction hors ligne possible si l'installateur a désactivé cloud-init :
#   sudo virt-customize -a "$IMGDIR/$TEMPLATE" --delete /etc/cloud/cloud-init.disabled

sudo qemu-img check -f qcow2 "$IMGDIR/$TEMPLATE"
sudo sha256sum "$IMGDIR/$TEMPLATE"
echo ">> Template '$TEMPLATE' prêt : déployer avec un seed cloud-init NoCloud (voir tp2-cloud-init)"
