# Contenu attendu dans `images/` — fichiers volumineux non publiés

Les disques qcow2 des VM (2 à 5 Gio chacun) ne sont pas publiables sur GitHub (limite 100 Mo/fichier).
Ils vivent dans `/var/lib/libvirt/images/` de l'hôte KVM. Artefacts produits pendant le TP1 :

| Fichier | Taille virtuelle / réelle | Rôle | État |
|---|---|---|---|
| `ubuntu-vm01.qcow2` | 15 Gio / ~4,4 Gio | VM source (hostname `srv-source`), installée depuis l'ISO vérifiée via `02-create-vm.sh` | supprimée après capture complète des preuves (espace disque) |
| `ubuntu-vm02.qcow2` | 15 Gio / ~4,4 Gio | **Clone complet** (Exercice 6) : disque indépendant, sans backing file | supprimée après preuves |
| `ubuntu-os-capture-v1.qcow2` | 15 Gio / 4,42 Gio | **Image d'OS capturée** (Exercice 7), SHA-256 enregistré dans `preuves/capture.sha256` | supprimée après réimport testé |
| `ubuntu-restore01.qcow2` | 15 Gio / ~4,4 Gio | **Réimportation testée** (Exercice 8) : démarre sans installation, témoin retrouvé | supprimée après preuves |

Preuves correspondantes (locales) : `preuves/06-exercice6-clone.txt`, `preuves/07-exercice7-capture.txt`,
`preuves/08-exercice8-reimport.txt`, `preuves/capture.sha256`.
