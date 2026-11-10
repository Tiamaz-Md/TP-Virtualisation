# TP Virtualisation et Cloud Computing — Master BD2C (FSAC)

Dépôt de suivi des travaux pratiques du module **Virtualisation et Cloud Computing**.

> Étudiant : Mouad T. — Année universitaire 2026/2027 — Ce dépôt permet de suivre l'avancement du projet : chaque partie terminée est poussée avec son code/config.

## État d'avancement

| TP | Sujet | État | Livrable |
|---|---|---|---|
| **TP1 — KVM/QEMU et libvirt** (VM, clones, images d'OS, templates) | [`B01_TP1.pdf`](B01_TP1.pdf) | ✅ **Terminé** (2026-11-10) | Scripts & configs : [`TP1/scripts/`](TP1/scripts/) |
| **TP2 — Cloud-Init** (NoCloud, profils, Jinja2, multi-VM) | [`B02_TP2_CloudInit.pdf`](B02_TP2_CloudInit.pdf) | ✅ **Terminé** (2026-11-10) | Projet : [`TP2/projet/`](TP2/projet/) |

## TP1 — Virtualisation avec KVM/QEMU et libvirt

Environnement : hôte **Ubuntu Server 26.10** dans VMware Workstation (virtualisation imbriquée → `/dev/kvm`), VM source installée depuis l'ISO officielle **Ubuntu 24.04.5 Server** (checksum officiel vérifié). Parcours **Ubuntu**.

Ce dépôt contient le **code et les fichiers de configuration** utilisés pendant le TP ([`TP1/scripts/`](TP1/scripts/)) :

- `env.sh` — variables du parcours Ubuntu + utilitaires (attente d'arrêt, récupération d'IP, attente SSH)
- `install-command.sh` — `virt-install` de la VM source (autoinstall via boot direct kernel + seed `cidata`)
- `vm1-autoinstall-user-data` / `vm1-autoinstall-meta-data` — configuration autoinstall de `srv-source`
- `app01-nocloud-user-data` / `app01-nocloud-meta-data` — seeds cloud-init NoCloud des instances app01/app02

Détail de la chaîne d'usage : [`TP1/scripts/README.md`](TP1/scripts/README.md).

> **Preuves et compte rendu** : les fichiers de preuve (sorties brutes des exercices, XML, checksums, captures d'écran) et les comptes rendus complets sont **conservés localement sur la machine de travail** et ne sont pas publiés dans ce dépôt (conformément aux consignes : conserver les gros fichiers localement, ne déposer ni secret ni image).

## TP2 — Cloud-Init (terminé)

Déployé depuis l'image généralisée du TP1 (`base-cloud.qcow2`) : user-data/meta-data/network-config NoCloud, utilisateurs et SSH par clé (`ssh_pwauth: false`), réseau DHCP puis statique, nginx automatisé, **3 profils YAML** (web/db/admin), **template Jinja2** + `generate.py` + inventaire → génération et déploiement de **web01 (nginx), db01 (PostgreSQL 16), admin01 (outils)** en fonctionnement simultané, diagnostic cloud-init (schema/analyze/logs) avec cas d'erreur volontaire corrigé.

Code publié : [`TP2/projet/`](TP2/projet/) — `nocloud/` (seeds), `templates/user-data.j2`, `profiles/`, `inventory/vms.yml`, `generated/`, `generate.py`.

## Arborescence

```
├── B01_TP1.pdf                 Sujet TP1
├── B02_TP2_CloudInit.pdf       Sujet TP2
├── TP1/
│   └── scripts/                Code/config : env.sh, autoinstall, seeds NoCloud (+ README d'usage)
└── TP2/
    └── projet/                 Code/config : nocloud/, templates/, profiles/, inventory/, generated/, generate.py
```
