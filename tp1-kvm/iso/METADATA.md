# Contenu attendu dans `iso/` — fichiers volumineux non publiés

GitHub refuse les fichiers > 100 Mo : les ISO restent **localement** (consigne du TP).
Ce dossier contient donc uniquement ce descriptif ; les fichiers réels sont aux emplacements indiqués.

| Fichier | Taille | SHA-256 | Emplacements réels |
|---|---|---|---|
| `ubuntu-24.04.5-live-server-amd64.iso` | 4 080 486 400 octets (4,08 Go) | `97f3d7ffb032c3eb3b23d2c8be9cc76e60c2c1f2c0146ba5ba9fe01cafae0fd8` (= valeur officielle de releases.ubuntu.com/24.04, vérifiée au TP1) | hôte KVM : `/var/lib/libvirt/boot/ubuntu.iso` (copiée par l'exercice 3) • Windows : `C:\Users\Tmz\Documents\ISO\` |
| `rocky-9-minimal.iso` | — | — | non téléchargée : **parcours Ubuntu** choisi pour l'ensemble du TP |

Téléchargement/reproduction : `https://releases.ubuntu.com/24.04/ubuntu-24.04.5-live-server-amd64.iso`
puis vérification : `sha256sum -c` avec le fichier `SHA256SUMS` publié par la distribution.
