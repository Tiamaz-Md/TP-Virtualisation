# `images/` — disques des VM du TP1 (copies locales, présentes ici)

Copies locales au format **qcow2 compressé** (`qemu-img convert -c`) : 100 % utilisables
par qemu/libvirt (`virt-install --import`), au poids réduit pour le transport.
Les disques d'origine de la séance du 2026-11-10 ont été supprimés de l'hôte pour libérer
l'espace requis par le TP2 ; ceux-ci sont la **reproduction du 2026-11-11** obtenue en rejouant
`scripts/02-create-vm.sh` puis `scripts/03-clone-vm.sh` (identités neuves, même procédure).

| Fichier | Taille virtuelle / fichier | Rôle |
|---|---|---|
| `ubuntu-vm01.qcow2` | 15 Gio / 2,12 Go (compressé) | VM source (hostname `srv-source`), installée depuis l'ISO vérifiée |
| `ubuntu-vm02.qcow2` | 15 Gio / 2,12 Go (compressé) | **Clone complet** (disque indépendant, sans backing file) |

Identités libvirt de la reproduction : UUID `cc7b510c…` / `1c5f9b79…`, MAC `52:54:00:45:ac:29` / `52:54:00:66:34:4c`.
Les VM d'origine (exécution du 2026-11-10 documentée dans `preuves/`) ont été supprimées de l'hôte ;
copies exportées via `qemu-img convert -c` le 2026-11-11.
