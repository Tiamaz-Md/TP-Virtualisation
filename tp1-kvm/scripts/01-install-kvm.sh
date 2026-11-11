#!/usr/bin/env bash
# 01-install-kvm.sh — TP1 Partie A : vérifier la virtualisation, installer et contrôler les outils
# Usage : ./01-install-kvm.sh
set -euo pipefail

echo "=== Diagnostic matériel (Exercice 1) ==="
lscpu | grep -Ei "model name|virtualization" || true
echo "CPU avec extensions vmx/svm : $(grep -Eoc '(vmx|svm)' /proc/cpuinfo || echo 0)"
lsmod | grep kvm || echo "modules kvm non chargés"
test -e /dev/kvm && ls -l /dev/kvm
df -h /var/lib/libvirt 2>/dev/null || df -h /var

echo
echo "=== Installation des outils (parcours Ubuntu — Exercice 2) ==="
sudo apt-get update
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients \
  virtinst virt-manager virt-viewer qemu-utils libguestfs-tools genisoimage
# Note Ubuntu 26.10 : qemu-kvm est un paquet virtuel fourni par qemu-system-x86
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"

echo
echo "=== Contrôle (connexion système + outils) ==="
sudo virsh -c qemu:///system list --all
for c in virt-install virt-clone qemu-img virt-sysprep genisoimage; do
  printf "%-14s: %s\n" "$c" "$(command -v "$c" || echo ABSENT)"
done
echo ">> Déconnexion/reconnexion requise pour appliquer les groupes libvirt,kvm"
