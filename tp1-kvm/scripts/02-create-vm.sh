#!/usr/bin/env bash
# 02-create-vm.sh — TP1 Partie B (Exercices 3 et 4) : créer une VM depuis l'ISO
# Usage :
#   ./02-create-vm.sh <nom-vm> [chemin-iso] [chemin-seed-cidata]
#   SEED fourni  -> installation non interactive par autoinstall (kernel casper de l'ISO
#                   + cmdline « autoinstall » + seed cidata en second cdrom)
#   SEED absent  -> installation interactive classique depuis l'ISO (console VNC)
# Exemples :
#   ./02-create-vm.sh ubuntu-vm01 /var/lib/libvirt/boot/ubuntu.iso /var/lib/libvirt/images/seed-vm01.iso
#   ./02-create-vm.sh ubuntu-vm01 /var/lib/libvirt/boot/ubuntu.iso
set -euo pipefail

NAME="${1:?nom de VM requis}"
ISO="${2:-/var/lib/libvirt/boot/ubuntu.iso}"
SEED="${3:-}"
IMGDIR="${IMGDIR:-/var/lib/libvirt/images}"
DISK="$IMGDIR/$NAME.qcow2"
OSVARIANT="${OSVARIANT:-ubuntu24.04}"

[ -f "$ISO" ] || { echo "ISO introuvable : $ISO"; exit 1; }
[ -e "$DISK" ] && { echo "Refus : $DISK existe déjà (ne jamais écraser)"; exit 1; }

# Réseau NAT « default » actif et autostart
sudo virsh -c qemu:///system net-start default 2>/dev/null || true
sudo virsh -c qemu:///system net-autostart default >/dev/null

BASE=(--connect qemu:///system
  --name "$NAME" --memory 2048 --vcpus 2
  --disk path="$DISK",size=15,format=qcow2,bus=virtio
  --network network=default,model=virtio
  --channel unix,target_type=virtio,name=org.qemu.guest_agent.0
  --os-variant "$OSVARIANT"
  --graphics vnc,listen=127.0.0.1 --noautoconsole)

if [ -n "$SEED" ]; then
  # Installation automatisée (autoinstall) : kernel/initrd casper extraits de l'ISO
  # (cf. rapport TP1, exercice 4) et args Grub reproduits + autoinstall.
  KDIR=/var/lib/libvirt/boot/kernel
  sudo mkdir -p "$KDIR"
  sudo mount -o loop,ro "$ISO" /mnt/iso 2>/dev/null || true
  sudo cp /mnt/iso/casper/vmlinuz /mnt/iso/casper/initrd "$KDIR/" 2>/dev/null \
    || { echo "Extraction casper impossible (montez l'ISO manuellement)"; exit 1; }
  sudo chmod 644 "$KDIR"/*
  sudo virt-install "${BASE[@]}" \
    --disk path="$SEED",device=cdrom,readonly=on \
    --boot kernel="$KDIR/vmlinuz",initrd="$KDIR/initrd",cmdline="autoinstall console=ttyS0,115200n8 ---" \
    --disk path="$ISO",device=cdrom,readonly=on
else
  sudo virt-install "${BASE[@]}" --cdrom "$ISO"
fi

echo ">> VM '$NAME' lancée. Suivre l'installation puis, une fois terminée :"
echo ">>   éjecter l'ISO et démarrer sur le disque (virsh change-media / dumpxml), cf. rapport TP1"
