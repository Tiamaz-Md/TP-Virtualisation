# Variables du TP1 - Parcours Ubuntu
export PREFIX=ubuntu
export OSVAR=ubuntu24.04
export ISO=/var/lib/libvirt/boot/ubuntu.iso
export VM="${PREFIX}-vm01"
export CLONE="${PREFIX}-vm02"
export RESTORE="${PREFIX}-restore01"
export IMGDIR=/var/lib/libvirt/images
export DISK="$IMGDIR/$VM.qcow2"
export CAPTURE="$IMGDIR/${PREFIX}-os-capture-v1.qcow2"
export TEMPLATE="$IMGDIR/${PREFIX}-template-v1.qcow2"
vsh() { sudo virsh -c qemu:///system "$@"; }
wait_shutdown() {
  local name="$1" i=0 state
  while [ $i -lt 90 ]; do
    state=$(sudo virsh -c qemu:///system domstate "$name" 2>/dev/null | tr -d '\n')
    [ "$state" = "shut off" ] && { echo "$name : arret effectif"; return 0; }
    sleep 2; i=$((i+1))
  done
  echo "$name : toujours '$state' apres 180s"; return 1
}
guest_ip() {
  local name="$1" ip="" i=0 mac
  while [ $i -lt 80 ]; do
    ip=$(sudo virsh -c qemu:///system domifaddr "$name" --source agent 2>/dev/null | awk '/ipv4/ {print $4}' | grep -v '^127\.' | cut -d/ -f1 | head -1)
    if [ -z "$ip" ]; then
      mac=$(sudo virsh -c qemu:///system domiflist "$name" 2>/dev/null | awk '/network/ {print $5}')
      ip=$(sudo virsh -c qemu:///system net-dhcp-leases default 2>/dev/null | awk -v m="$mac" 'tolower($0) ~ tolower(m) {print $5}' | cut -d/ -f1 | head -1)
    fi
    [ -n "$ip" ] && { echo "$ip"; return 0; }
    sleep 3; i=$((i+1))
  done
  return 1
}
wait_ssh() {
  local ip="$1" i=0
  while [ $i -lt 90 ]; do
    ssh -n -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -o BatchMode=yes etudiant@"$ip" true 2>/dev/null && return 0
    sleep 5; i=$((i+1))
  done
  return 1
}
