#!/usr/bin/env bash
# 05-manage-vm.sh — TP1 Partie B (Exercice 5) : administrer le cycle de vie d'une VM
# Usage : ./05-manage-vm.sh <start|shutdown|stop|reboot|list|info|ip> [nom-vm]
set -euo pipefail

CMD="${1:?usage: $0 <start|shutdown|stop|reboot|list|info|ip> [nom-vm]}"
VM="${2:-}"
VIRSH="sudo virsh -c qemu:///system"

case "$CMD" in
  list)
    $VIRSH list --all ;;
  start)
    $VIRSH start "${VM:?nom requis}" ;;
  shutdown)
    # Arrêt propre (ACPI) : shutdown ne bloque pas -> attendre l'arrêt effectif
    $VIRSH shutdown "${VM:?nom requis}"
    for _ in $(seq 1 60); do
      [ "$($VIRSH domstate "$VM" | tr -d '\n')" = "shut off" ] && { echo "arrêt effectif"; exit 0; }
      sleep 2
    done
    echo "toujours en cours après 120 s"; exit 1 ;;
  stop)
    # Arrêt brutal (équivalent débranchement) — ne supprime pas le disque
    $VIRSH destroy "${VM:?nom requis}" ;;
  reboot)
    $VIRSH reboot "${VM:?nom requis}" ;;
  info)
    for k in dominfo domblklist domiflist; do
      echo "--- $k ${VM:?nom requis} ---"; $VIRSH "$k" "$VM"
    done
    $VIRSH dumpxml "${VM:?nom requis}" > "${VM}.xml"
    echo "définition exportée : ${VM}.xml" ;;
  ip)
    # IP via l'agent invité puis, à défaut, via les baux DHCP du réseau default
    ip=$($VIRSH domifaddr "${VM:?nom requis}" --source agent 2>/dev/null \
         | awk '/ipv4/ && $4 !~ /^127\./ {print $4}' | cut -d/ -f1 | head -1)
    [ -z "$ip" ] && { mac=$($VIRSH domiflist "$VM" | awk '/network/ {print $5}'); \
      ip=$($VIRSH net-dhcp-leases default | awk -v m="$mac" 'tolower($0) ~ tolower(m) {print $5}' | cut -d/ -f1 | head -1); }
    echo "$VM : $ip" ;;
  *)
    echo "Commande inconnue : $CMD"; exit 1 ;;
esac
