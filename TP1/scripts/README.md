# TP1 — Scripts et fichiers de configuration utilisés

Fichiers de configuration/code réellement utilisés pendant le TP1 (KVM/QEMU et libvirt).
Les preuves d'exécution et le compte rendu complet sont conservés localement (non publiés ici).

| Fichier | Rôle |
|---|---|
| `env.sh` | Variables du parcours Ubuntu (`PREFIX`, `OSVAR`, `VM`, `CLONE`, `DISK`, `CAPTURE`, `TEMPLATE`…) + fonctions utilitaires (`wait_shutdown`, `guest_ip`, `wait_ssh`) sourcées dans chaque terminal de travail |
| `install-command.sh` | Commande `virt-install` de création de la VM source `ubuntu-vm01` : 2 vCPU, 2 048 MiB, 15 Gio qcow2 VirtIO, réseau NAT `default`, canal `org.qemu.guest_agent.0`, `--os-variant ubuntu24.04`, VNC sur 127.0.0.1. Le boot direct kernel (`--boot kernel=…,initrd=…,cmdline="autoinstall console=ttyS0,115200n8 ---"`) permet l'installation non interactive depuis l'ISO 24.04.5 (kernel/initrd `casper` extraits de l'ISO, seed `cidata` attachée en second cdrom) |
| `vm1-autoinstall-user-data` | Configuration **autoinstall** (cloud-init) de la VM source : hostname `srv-source`, compte pédagogique `etudiant`, DHCP sans liaison MAC, serveur SSH, partitionnement simple sans chiffrement (`storage: layout: direct`), paquets (openssh-server, cloud-init, qemu-guest-agent), `shutdown: poweroff` |
| `vm1-autoinstall-meta-data` | `instance-id` / `local-hostname` du support cidata (seed ISO créée avec `genisoimage -volid cidata -joliet -rock`) |
| `app01-nocloud-user-data` | `user-data` **NoCloud** du déploiement des instances depuis le template (Partie F) : hostname personnalisé, clés SSH hôte régénérées, compte `etudiant` par clé publique avec sudo NOPASSWD, fichier témoin `/etc/tp-instance`. Version identique pour app02 (seuls hostname/instance-id changent) |
| `app01-nocloud-meta-data` | `instance-id: tp1-ubuntu-app01-v1` — l'identité d'instance distincte qui déclenche le premier démarrage cloud-init de chaque copie du template |

## Chaîne d'usage (résumé)

1. `source env.sh` puis `install-command.sh` → VM source installée depuis l'ISO vérifiée (SHA-256 officiel)
2. Partie C : `virt-clone` → clone complet (identités observées, disques indépendants)
3. Partie D : `qemu-img convert` → capture, `virt-install --import` → test de réimportation
4. Partie E : copie du disque → `virt-sysprep --operations machine-id,ssh-hostkeys,udev-persistent-net,logfiles,tmp-files,bash-history` → template généralisé
5. Partie F : par instance — `qemu-img convert` du template, `virt-sysprep --enable customize` (graine aléatoire), seed `cidata` (`user-data` + `meta-data` via `genisoimage`), `virt-install --import` + seed → app01/app02 avec identités distinctes
