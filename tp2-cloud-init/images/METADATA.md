# Contenu attendu dans `images/` — fichiers volumineux non publiés

| Fichier | Taille virtuelle / réelle | SHA-256 | Emplacement réel |
|---|---|---|---|
| `base-cloud.qcow2` | 15 Gio / 2,16 Go (2 345 566 208 octets) | `4abc0ab64eb41d9c0dd21508e7e7c24abcee7e40a9173dfd43e57daee50e379a` | hôte KVM : `/var/lib/libvirt/images/base-cloud.qcow2` |
| `rocky-template.qcow2` | — | — | non réalisé : **parcours Ubuntu** |

`base-cloud.qcow2` = copie **compressée** (`qemu-img convert -c`) du template généralisé du TP1
(`ubuntu-template-v1.qcow2`, qui reste intact). C'est l'image de base utilisée par
`scripts/deploy.sh` pour créer un disque indépendant par VM (`virt-install --import`).
