# TP Virtualisation et Cloud Computing — Master BD2C (FSAC)

Dépôt de suivi des travaux pratiques du module **Virtualisation et Cloud Computing**.

> Étudiant : Mouad T. — Année universitaire 2026/2027 — Ce dépôt permet de suivre l'avancement du projet : chaque partie terminée est poussée avec ses preuves.

## État d'avancement

| TP | Sujet | État | Livrable |
|---|---|---|---|
| **TP1 — KVM/QEMU et libvirt** (VM, clones, images d'OS, templates) | [`B01_TP1.pdf`](B01_TP1.pdf) | ✅ **Terminé** (2026-11-10) | [`TP1/RAPPORT.md`](TP1/RAPPORT.md) |
| TP2 — Cloud-init | [`B02_TP2_CloudInit.pdf`](B02_TP2_CloudInit.pdf) | ⏳ À venir | — |

## TP1 — Virtualisation avec KVM/QEMU et libvirt

Environnement : hôte **Ubuntu Server 26.10** dans VMware Workstation (virtualisation imbriquée → `/dev/kvm`), VM source installée depuis l'ISO officielle **Ubuntu 24.04.5 Server** (checksum officiel vérifié). Parcours **Ubuntu**.

Résumé de ce qui a été réalisé et prouvé (voir [`TP1/RAPPORT.md`](TP1/RAPPORT.md)) :

- **Partie A** — Diagnostic matériel KVM (`svm` ×4, `/dev/kvm`, modules `kvm_amd`), outils libvirt vérifiés sur `qemu:///system`
- **Partie B** — VM `ubuntu-vm01` (srv-source) installée depuis l'ISO 24.04.5 vérifiée SHA-256 ; administration complète (`dominfo/domblklist/domiflist/dumpxml`), agent invité, arrêt/redémarrage
- **Partie C** — Clone complet `ubuntu-vm02` : disque indépendant prouvé, tableau des identités (UUID/MAC différents ; machine-id/hostname/clé SSH copiés), **conflit IP réellement observé** puis tests successifs réussis
- **Partie D** — Capture `ubuntu-os-capture-v1.qcow2` (fiche image + SHA-256), réimportée et testée : démarrage sans installation, témoin retrouvé
- **Partie E** — Template `ubuntu-template-v1.qcow2` généralisé sur une copie (`virt-sysprep` : machine-id, ssh-hostkeys, udev-persistent-net, logfiles, tmp-files, bash-history), fiche versionnée
- **Partie F** — Deux instances `app01`/`app02` déployées depuis le template avec seeds cloud-init NoCloud : **toutes les identités distinctes**, template inchangé (`sha256sum -c` OK), fonctionnement simultané sans conflit réseau
- **Partie G** — RAW vs QCOW2 avec sorties réelles (RAW sparse : 5,0 G apparents / 4 K réels ; `qemu-img compare` : *Images are identical*)
- **Partie H** — 8 études de cas argumentées + approfondissement *backing file* (overlay créé, non démarré)
- **Preuves** : 32 fichiers bruts dans [`TP1/preuves/`](TP1/preuves/), scripts d'automatisation dans [`TP1/scripts/`](TP1/scripts/)

## Arborescence

```
├── B01_TP1.pdf                 Sujet TP1
├── B02_TP2_CloudInit.pdf       Sujet TP2
└── TP1/
    ├── RAPPORT.md              Compte rendu complet (livrable)
    ├── preuves/                Sorties brutes, XML, checksums, captures d'écran
    └── scripts/                env.sh, autoinstall srv-source, seeds NoCloud app01
```

> Note : conformément au TP, les images QCOW2 volumineuses et les ISO restent sur l'hôte (aucune clé privée ni secret n'est déposé ici ; les mots de passe des VM de laboratoire sont documentés dans le rapport comme le demande la fiche du template).
