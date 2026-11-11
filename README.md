# TP Virtualisation et Cloud Computing — Master BD2C (FSAC)

Dépôt de suivi des travaux pratiques du module **Virtualisation et Cloud Computing** (2026/2027).
Les fichiers volumineux (ISO, images qcow2) et les preuves/comptes rendus restent **locaux** (voir les README de chaque TP).

| TP | Sujet | État | Code |
|---|---|---|---|
| **TP1 — KVM/QEMU et libvirt** | [`B01_TP1.pdf`](B01_TP1.pdf) | ✅ Terminé (2026-11-10) | [`tp1-kvm/scripts/`](tp1-kvm/scripts/) |
| **TP2 — Cloud-Init** | [`B02_TP2_CloudInit.pdf`](B02_TP2_CloudInit.pdf) | ✅ Terminé (2026-11-10) | [`tp2-cloud-init/`](tp2-cloud-init/) |

## TP1 — KVM/QEMU et libvirt (`tp1-kvm/`)

VM installée depuis une ISO officielle vérifiée, clone complet avec analyse des identités, capture d'image d'OS réimportée, template généralisé (`virt-sysprep`) — scripts reproductibles `01-install-kvm.sh` → `05-manage-vm.sh`.

## TP2 — Cloud-Init (`tp2-cloud-init/`)

Déploiement automatisé depuis l'image généralisée du TP1 : seeds NoCloud, SSH par clé, réseau DHCP/statique, nginx ; profils YAML (web/database/admin) + templates Jinja2 + inventaire → `generate.py` → `deploy.sh` → **web01** (nginx), **db01** (PostgreSQL), **admin01**.

```
TP1 :  scripts/01..05  (install, create, clone, template, manage)
TP2 :  inventaire/vms.yaml + profiles/ + templates/ -> generate.py -> output/ -> deploy.sh -> KVM
```

> Environnement : hôte Ubuntu Server dans VMware Workstation (virtualisation imbriquée), invités Ubuntu 24.04 Server. Parcours Ubuntu.
