# `templates/` — template généralisé (copie locale, présente ici)

| Fichier | Taille virtuelle / fichier | SHA-256 | Emplacements |
|---|---|---|---|
| `ubuntu-template-v1.qcow2` | 15 Gio / 4,43 Go (4 754 243 584 octets) | `c41241cb1d6a90cf6abe055d4f9480aa49aa7cb287d5a9dae3eeda6079190805` | **ce dossier** • hôte KVM : `/var/lib/libvirt/images/ubuntu-template-v1.qcow2` |
| `rocky-template.qcow2` | — | — | non réalisé : **parcours Ubuntu** |

**Génération** : `scripts/04-create-template.sh` — copie de la VM source (`qemu-img convert`)
puis généralisation sur la **copie** : `virt-sysprep --operations machine-id,ssh-hostkeys,udev-persistent-net,logfiles,tmp-files,bash-history`.

Réutilisé par le TP2 (copie de travail compressée `base-cloud.qcow2`) — intégrité vérifiée
après déploiement des instances : `sha256sum -c` → OK.
