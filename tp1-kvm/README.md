# TP1 — KVM : VM, clones, images d'OS et templates

**Module** : Virtualisation et Cloud Computing — Master BD2C (FSAC) — Parcours **Ubuntu**
Hôte : VM Ubuntu Server (VMware Workstation, virtualisation imbriquée `/dev/kvm`) — Invité de référence : Ubuntu 24.04.5 Server (ISO officielle, SHA-256 vérifié).

## Arborescence du projet

```
tp1-kvm/
├── iso/                     ISO d'installation (fichiers volumineux conservés localement)
│   └── ubuntu-24.04.5-live-server-amd64.iso      (4,08 Go — SHA-256 officiel vérifié)
├── images/                  Disques des VM (qcow2, conservés sur l'hôte KVM)
│   └── ubuntu-vm01.qcow2, ubuntu-vm02.qcow2 (clone), …
├── templates/               Images généralisées (qcow2, conservées sur l'hôte KVM)
│   └── ubuntu-template-v1.qcow2                 (virt-sysprep, SHA-256 enregistré)
├── scripts/
│   ├── 01-install-kvm.sh        Partie A  : diagnostic matériel + installation et contrôle des outils
│   ├── 02-create-vm.sh          Partie B  : création de la VM depuis l'ISO (autoinstall si seed fournie)
│   ├── 03-clone-vm.sh           Partie C  : clone complet + vérification des identités
│   ├── 04-create-template.sh    Parties D/E : capture (qemu-img convert) + généralisation (virt-sysprep)
│   └── 05-manage-vm.sh          Partie B  : cycle de vie (start/shutdown/stop/list/info/ip)
└── README.md                Ce fichier
```

> **Fichiers volumineux** : les ISO (Go) et les images qcow2 ne sont pas publiés dans le dépôt — ils sont conservés localement : ISO sur `C:\Users\Tmz\Documents\ISO\` et dans `/var/lib/libvirt/boot/ubuntu.iso` sur l'hôte KVM ; images et templates dans `/var/lib/libvirt/images/` de l'hôte (`ubuntu-template-v1.qcow2` = livrable du TP1, base du TP2).

## Usage des scripts (sur l'hôte KVM)

```bash
./scripts/01-install-kvm.sh                          # diagnostic + outils + libvirtd
./scripts/02-create-vm.sh ubuntu-vm01 $ISO $SEED     # création (autoinstall si seed cidata fournie)
./scripts/03-clone-vm.sh ubuntu-vm01 ubuntu-vm02     # clone complet + contrôle des identités
./scripts/04-create-template.sh ubuntu-vm01          # capture + sysprep -> template généralisé
./scripts/05-manage-vm.sh info ubuntu-vm01           # dominfo / domblklist / domiflist / dumpxml
./scripts/05-manage-vm.sh ip ubuntu-vm01             # IP via agent invité ou bail DHCP
```

## Résultats marquants (détails dans le compte rendu local `RAPPORT.md`)

- VM source installée depuis l'ISO vérifiée ; administration complète (`virsh`), agent invité, cycle de vie maîtrisé
- Clone complet : disque indépendant (aucun backing file) ; UUID/MAC renouvelés par `virt-clone`, machine-id/hostname/clé SSH hôte **copiés** ; conflit d'IP observé lors d'un démarrage simultané (même bail redemandé par le clone) — tests successifs concluants
- Image d'OS capturée, checksumée et **réimportée avec succès** (démarrage sans installation)
- Template généralisé sur une **copie** (`virt-sysprep` : machine-id, ssh-hostkeys, udev-persistent-net, logfiles, tmp-files, bash-history), versionné par SHA-256
