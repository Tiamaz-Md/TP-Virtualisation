#!/usr/bin/env bash
# 03-clone-vm.sh — TP1 Partie C (Exercice 6) : créer un clone complet d'une VM arrêtée
# Usage : ./03-clone-vm.sh <vm-source> <nom-clone>
set -euo pipefail

SRC="${1:?vm source requise}"
CLONE="${2:?nom du clone requis}"
IMGDIR="${IMGDIR:-/var/lib/libvirt/images}"
VIRSH="sudo virsh -c qemu:///system"

# Arrêt propre + attente de l'arrêt effectif (shutdown ne bloque pas)
$VIRSH shutdown "$SRC" 2>/dev/null || true
for _ in $(seq 1 60); do
  [ "$($VIRSH domstate "$SRC" | tr -d '\n')" = "shut off" ] && break
  sleep 2
done
[ "$($VIRSH domstate "$SRC" | tr -d '\n')" = "shut off" ] || { echo "La VM source tourne encore"; exit 1; }

sudo virt-clone --connect qemu:///system --original "$SRC" --name "$CLONE" \
  --file "$IMGDIR/$CLONE.qcow2"

echo "=== Identités libvirt (attendues différentes) ==="
echo "UUID $SRC  : $($VIRSH domuuid "$SRC")"
echo "UUID $CLONE: $($VIRSH domuuid "$CLONE")"
echo "MAC  $SRC  : $($VIRSH domiflist "$SRC" | awk '/network/ {print $5}')"
echo "MAC  $CLONE: $($VIRSH domiflist "$CLONE" | awk '/network/ {print $5}')"

echo "=== Disque du clone (aucun backing file attendu) ==="
sudo qemu-img info "$IMGDIR/$CLONE.qcow2" | grep -E "^image|virtual size|disk size|backing"
echo ">> Attention : machine-id, hostname et clés SSH hôte restent identiques (cf. rapport)"
