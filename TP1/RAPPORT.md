# TP n°1 — Virtualisation avec KVM/QEMU et libvirt

**Module** : Virtualisation et Cloud Computing — Master BD2C, FSAC (2026/2027)
**Parcours choisi** : Ubuntu (l'ensemble du TP suit ce parcours)
**Rendu** : 2026-11-10 — toutes les valeurs de ce rapport proviennent des sorties réellement observées (dossier [`preuves/`](preuves/))

---

## 1. Description du poste hôte et du parcours choisi

L'hôte du TP est une **machine virtuelle Ubuntu Server 26.10 exécutée dans VMware Workstation** sur un PC Windows 11 (MSI Bravo 15, AMD Ryzen 7 7735HS). La **virtualisation imbriquée** est activée dans VMware (l'invité expose `svm` et fournit `/dev/kvm`), ce qui fait de cette VM l'hôte KVM/libvirt du TP. Le TP indique « Ubuntu 24.04 LTS ou Rocky Linux 9 » pour l'hôte : l'environnement disponible étant Ubuntu Server 26.10 (même famille, mêmes paquets `libvirt-daemon-system`, `virtinst`, `qemu-utils`, `libguestfs-tools`), le parcours Ubuntu a été conservé et l'écart de version est documenté ici. La **VM source invitée** (`ubuntu-vm01`) est, elle, installée depuis l'ISO officielle **Ubuntu 24.04.5 Server** conformément au sujet.

| Caractéristique de l'hôte | Valeur observée |
|---|---|
| OS hôte | Ubuntu Server 26.10 « stonking » (noyau 7.3.0-9-generic), VM VMware |
| CPU exposé | 4 vCPU AMD Ryzen 7 7735HS — `Virtualization: AMD-V`, `Hypervisor vendor: VMware` |
| RAM / disque | 15 Gi RAM ; 48 Go de disque (38 Go libres) |
| Réseau | NAT libvirt `default` (bridge `virbr0`, 192.168.122.0/24) |
| Connexion | `qemu:///system`, utilisateur `tmz` (membre des groupes `libvirt`, `kvm`) |

> Une VM nommée `srv-source` (disque quasi vide, 78 MiB utilisés) était présente sur l'hôte avant le TP : elle a été **laissée intacte** et n'a pas été utilisée ; le TP a recréé une VM complète `ubuntu-vm01`.

## 2. Diagnostic KVM/libvirt (Partie A — Exercices 1 et 2)

Preuve complète : [`preuves/01-exercice1-diagnostic.txt`](preuves/01-exercice1-diagnostic.txt)

| Commande | Résultat observé | Interprétation |
|---|---|---|
| `grep -Eoc '(vmx|svm)' /proc/cpuinfo` | **4** | Les extensions AMD-V (`svm`) sont exposées à l'OS sur les 4 CPU. Un compteur non nul montre que les extensions sont exposées, sans valider seul KVM |
| `lsmod \| grep kvm` | `kvm_amd 270336`, `kvm 1585152` | Modules noyau chargés (`kvm_amd` pour AMD — `vmx` = Intel VT-x, `svm` = AMD-V) |
| `test -e /dev/kvm && ls -l /dev/kvm` | `crw-rw----+ root kvm` | Le périphérique KVM existe ; c'est la validation effective du fonctionnement |
| `df -h /var/lib/libvirt` | 48 Go, 38 Go libres | Espace suffisant pour les images du TP |
| `lscpu` | `Virtualization: AMD-V` | Architecture x86_64, CPU AMD |

Installation et contrôle des outils (preuve : [`preuves/02-exercice2-outils.txt`](preuves/02-exercice2-outils.txt)) :

- `systemctl is-active libvirtd` → **active**
- `sudo virsh -c qemu:///system list --all` → répond (connexion `qemu:///system` opérationnelle)
- Outils vérifiés : `virt-install`, `virt-clone`, `qemu-img`, `virt-sysprep`, `genisoimage` — tous présents
- **Difficulté documentée** : sur Ubuntu 26.10, le paquet `qemu-kvm` est un *paquet virtuel* « sans candidat » ; son fournisseur réel est `qemu-system-x86` (déjà installé, version `1:11.0.3+ds-2ubuntu2`). Conformément à la consigne du TP (« rechercher son fournisseur »), la correspondance a été vérifiée avec `apt-cache policy` et le TP s'est poursuivi avec tous les outils requis présents.

### Variables de travail (preuve : [`preuves/00-variables.txt`](preuves/00-variables.txt))

```bash
export PREFIX=ubuntu
export OSVAR=ubuntu24.04
export ISO=/var/lib/libvirt/boot/ubuntu.iso
export VM=ubuntu-vm01  CLONE=ubuntu-vm02  RESTORE=ubuntu-restore01
export IMGDIR=/var/lib/libvirt/images
export DISK=$IMGDIR/ubuntu-vm01.qcow2
export CAPTURE=$IMGDIR/ubuntu-os-capture-v1.qcow2
export TEMPLATE=$IMGDIR/ubuntu-template-v1.qcow2
```

## 3. Préparation de l'ISO et du réseau (Exercice 3)

Preuve : [`preuves/03-exercice3-iso-reseau.txt`](preuves/03-exercice3-iso-reseau.txt)

- ISO **Ubuntu 24.04.5 live-server amd64** (4 080 486 400 octets) téléchargée depuis `releases.ubuntu.com/24.04`, copiée vers `/var/lib/libvirt/boot/ubuntu.iso`
- **Somme de contrôle vérifiée selon la procédure publiée par la distribution** (fichier `SHA256SUMS` de `releases.ubuntu.com/24.04`) :
  - attendu (officiel) : `97f3d7ffb032c3eb3b23d2c8be9cc76e60c2c1f2c0146ba5ba9fe01cafae0fd8`
  - obtenu : **identique** ✓
- Réseau `default` : `net-list --all` → `active`, `autostart yes` ; `net-autostart default` exécuté ; bridge `virbr0`

**Question — pourquoi une VM derrière le NAT accède-t-elle à Internet sans être directement accessible ?** La VM émet ses paquets vers l'hôte (bridge `virbr0`), qui effectue du NAT (masquerade) : à l'extérieur, tout apparaît comme venant de l'hôte. Les réponses sont re-routées vers la VM grâce à la table de translation. Les postes du réseau physique n'ont aucune route vers 192.168.122.0/24 et le trafic entrant n'est pas redirigé (aucune règle de port-forwarding dnsmasq), donc ils ne peuvent pas initier de connexion vers la VM : elle est protégée tout en pouvant sortir.

## 4. Création et administration de la VM (Partie B — Exercices 4 et 5)

### 4.1 Installation de `ubuntu-vm01` depuis l'ISO

Configuration cible **respectée** : 2 vCPU, 2 048 MiB de RAM, disque QCOW2 de 15 Gio, disque et réseau VirtIO, réseau NAT `default`. `virt-install --osinfo list | grep -Ei ubuntu` contient bien `ubuntu24.04` (preuve [`preuves/10-4-generalisation.txt`](preuves/10-4-generalisation.txt) et [`preuves/04-commande-install.txt`](preuves/04-commande-install.txt)).

Commande de création (preuve : [`preuves/04-commande-install.txt`](preuves/04-commande-install.txt)) :

```bash
sudo virt-install \
 --connect qemu:///system \
 --name "$VM" \
 --memory 2048 \
 --vcpus 2 \
 --disk path="$DISK",size=15,format=qcow2,bus=virtio \
 --disk path="/var/lib/libvirt/boot/ubuntu.iso",device=cdrom,readonly=on \
 --disk path="/var/lib/libvirt/boot/ubuntu-vm01-seed.iso",device=cdrom,readonly=on \
 --network network=default,model=virtio \
 --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
 --os-variant "$OSVAR" \
 --boot kernel=/var/lib/libvirt/boot/kernel/vmlinuz,initrd=/var/lib/libvirt/boot/kernel/initrd,kernel_args="autoinstall console=ttyS0,115200n8 ---" \
 --graphics vnc,listen=127.0.0.1 \
 --noautoconsole
```

> **Note de méthode** : pour suivre l'installation sans interface graphique sur l'hôte, l'installation Ubuntu a été rendue non interactive par la méthode officielle **autoinstall** : kernel/initrd casper extraits de l'ISO (`casper/vmlinuz`, `casper/initrd`, args Grub reproduits — preuve [`preuves/04-grubcfg-iso.txt`](preuves/04-grubcfg-iso.txt)), plus une ISO seed `cidata` créée avec `genisoimage` contenant `user-data`/`meta-data` (script [`scripts/vm1-autoinstall-user-data`](../TP1-scripts/vm1-autoinstall-user-data)). Cette configuration applique exactement les choix demandés par le TP : hostname **`srv-source`**, compte pédagogique local **`etudiant`** (aucune donnée personnelle), **DHCP** sans adresse statique ni liaison MAC, **serveur SSH** installé, **partitionnement simple sans chiffrement** (`storage: layout: direct`), puis éjection de l'ISO et démarrage sur le disque.

Pendant l'installation, un premier essai a échoué avec l'écran `Malformed autoinstall in 'shutdown' section` (diagnostiqué par `virsh screenshot`) : dans ce subiquity, `shutdown` attend `poweroff` (énumération) et non `true`. Corrigé puis relancé — installation terminée en ~23 minutes, arrêt automatique observé (`domstate` → `shut off`).

Après installation, « éjection » de l'ISO conforme au TP : suppression des deux cdrom et des entrées `kernel/initrd/cmdline` de la définition XML (preuves [`preuves/04-vm01-avant-ejection-iso.xml`](preuves/04-vm01-avant-ejection-iso.xml)), puis `boot dev='hd'` et démarrage sur le disque.

### 4.2 Administration de la source (Exercice 5)

Preuves : [`preuves/05-exercice5-admin-hote.txt`](preuves/05-exercice5-admin-hote.txt), [`preuves/source.xml`](preuves/source.xml), [`preuves/05-exercice5-dans-vm.txt`](preuves/05-exercice5-dans-vm.txt)

| Observation | Valeur |
|---|---|
| `dominfo ubuntu-vm01` | UUID `03b3f2fe-ab29-401f-b38c-4b77286aa9cb`, 2 CPU, 2 097 152 KiB, `apparmor` enforcing |
| `domblklist` | `vda` → `/var/lib/libvirt/images/ubuntu-vm01.qcow2` |
| `domiflist` | réseau `default`, modèle `virtio`, MAC `52:54:00:87:cb:5a` |
| Dans la VM | hostname `srv-source` — Ubuntu 24.04.5 LTS — kernel 6.8.0-149-generic |
| `cat /etc/machine-id` | `03b3f2feab29401fb38c4b77286aa9cb` |
| `ip -br addr` | `enp1s0 UP 192.168.122.44/24` (DHCP) |
| Fichier témoin | `/opt/tp1/version.txt` → `Version applicative TP1 : v1` |
| `ssh-keygen -lf` (ED25519) | `256 SHA256:mLujAqRzbj2qaBFqqtQWw/6/HFt1j0qfz4dZvshXz90 root@srv-source` |
| `systemctl status qemu-guest-agent` | `active (running)` |
| `domifaddr --source agent` | `enp1s0 52:54:00:87:cb:5a ipv4 192.168.122.44/24` (agent fonctionnel) |
| `net-dhcp-leases default` | bail `srv-source` 192.168.122.44/24 visible |

Cycle de vie (preuve [`preuves/05-arret-demarrage.txt`](preuves/05-arret-demarrage.txt)) : `virsh shutdown` → arrêt **effectif** constaté à `shut off` après ~4 s (attente faite via `domstate`, car `shutdown` ne bloque pas), puis `virsh start` → `running`. Configuration enregistrée : `dumpxml` → `preuves/source.xml`.

**Questions Partie B :**

1. **`shutdown` vs `destroy`** : `shutdown` envoie une demande d'arrêt propre (ACPI) au système invité, qui ferme proprement ses services et systèmes de fichiers ; `destroy` coupe brutalement le processus QEMU (équivalent d'un débranchement de l'alimentation).
2. **Pourquoi `destroy` ne supprime pas le disque** : `destroy` agit sur le *processus de virtualisation* (l'instance en cours d'exécution), pas sur les données. Le disque est un fichier image distinct, simplement référencé par la définition XML ; il reste intact jusqu'à une action explicite (`undefine --remove-define-storage` ou suppression manuelle).
3. **Que supprime `undefine`** : la définition XML du domaine persistant (son « carte d'identité » côté libvirt). Par défaut il **conserve** le disque et les autres fichiers ; si la VM tourne, elle devient transitoire et disparaît à l'arrêt. La configuration réseau `default` et les images ne sont pas touchées.
4. **Pilotes VirtIO** : pilotes paravirtualisés de l'invité — les périphériques virtuels sont simplifiés et l'invité coopère avec l'hyperviseur au lieu d'émuler du matériel réel (IDE/e1000) : beaucoup moins d'aller-retours et de surcoût → débit disque et réseau nettement supérieurs.
5. **Pourquoi le XML seul ne suffit pas** : le XML décrit le matériel virtuel et des références (chemins des images) mais pas le *contenu* des disques, ni l'état du firmware/NVRAM, ni les secrets : sans l'image système, la machine « reconstituée » n'a rien à démarrer.

**Validation B : VM opérationnelle, fichier témoin présent, réseau fonctionnel et configuration enregistrée.** ✓

## 5. Clone complet et identités (Partie C — Exercice 6)

Preuves : [`preuves/06-exercice6-clone.txt`](preuves/06-exercice6-clone.txt), [`preuves/06-identites-source-clone.txt`](preuves/06-identites-source-clone.txt), [`preuves/06-conflit-ip-et-test-successif.txt`](preuves/06-conflit-ip-et-test-successif.txt)

```bash
sudo virt-clone --connect qemu:///system --original "$VM" --name "$CLONE" --file "$IMGDIR/$CLONE.qcow2"
```

`qemu-img info` du clone (VM arrêtée) : 15 GiB virtuels, **4.4 GiB réels**, format qcow2 — **aucun `backing file`** : le clone complet possède un disque indépendant.

Tableau complété avec les valeurs **réellement observées** :

| Élément | Source (ubuntu-vm01) | Clone (ubuntu-vm02) | Identique ou différent ? | Interprétation |
|---|---|---|---|---|
| Nom de la VM dans libvirt | `ubuntu-vm01` | `ubuntu-vm02` | **Différent** | Gestion de la VM |
| UUID libvirt | `03b3f2fe-ab29-401f-b38c-4b77286aa9cb` | `f9fdfdc1-31f8-4ffb-9338-57aabecc2f52` | **Différent** | Identité de la définition |
| Adresse MAC | `52:54:00:87:cb:5a` | `52:54:00:c7:76:ca` | **Différent** | Identité réseau virtuelle |
| Adresse IP et moment du relevé | 192.168.122.44 | 192.168.122.44 (**conflit observé**) | Identique au même moment | Dépend du réseau et du DHCP — voir ci-dessous |
| Nom d'hôte dans Linux | `srv-source` | `srv-source` | **Identique** | Identité interne de l'OS (copiée) |
| machine-id | `03b3f2feab29401fb38c4b77286aa9cb` | `03b3f2feab29401fb38c4b77286aa9cb` | **Identique** | Identité du système invité (copiée) |
| Empreinte de clé SSH hôte | `SHA256:mLujAqRzbj2q...` | `SHA256:mLujAqRzbj2q...` | **Identique** | Identité cryptographique du serveur (copiée) |
| Fichier `/opt/tp1/version.txt` | `Version applicative TP1 : v1` | `Version applicative TP1 : v1` | **Identique** | Contenu copié |

**Événement observé important** : démarrées **simultanément**, les deux VM ont reçu la **même IP** 192.168.122.44 malgré des MAC différentes. Le clone a copié l'état du client DHCP de la source, qui redemande explicitement son adresse précédente (et le machine-id identique peut aussi dupliquer le DUID) — le serveur dnsmasq honore la demande. Cela illustre la mise en garde du TP : *ne pas supposer que deux MAC différentes suffisent à garantir deux IP différentes*. Les tests ont donc été refaits **successivement** (comme le TP le prévoit), chaque VM recevant alors proprement le bail.

**Test d'indépendance des disques** : dans le clone → `echo "Modification propre au clone" | sudo tee /opt/tp1/clone.txt` (écrit et vérifié `cat` = OK) ; dans la source → `test ! -e /opt/tp1/clone.txt && echo "Disques indépendants : contrôle réussi"` → **« Disques indépendants : contrôle réussi »** ✓. Le clone a été arrêté avant de poursuivre.

**À expliquer :**

- **Nouvelle MAC mais même machine-id ?** La MAC est un identifiant *du matériel virtuel* : `virt-clone` renouvelle ce qui appartient à la définition libvirt. Le machine-id est un état *interne au système de fichiers invité* (`/etc/machine-id`) : l'outil de clonage ne modifie pas le système invité, il copie le disque tel quel.
- **Risques de clés SSH hôte dupliquées** : deux serveurs se présentant avec la même clé hôte sont indistinguables pour les clients SSH — un attaquant (ou un simple détournement DNS/IP) peut se faire passer pour l'un des deux sans déclencher d'alerte `MITM` ; les empreintes connues deviennent mensongères, et la révocation devient impossible.
- **Isoler un clone de production avant démarrage** : tant que le disque n'est pas généralisé, le clone réutilise les identités de la source (machine-id, DUID, état DHCP, clés) : démarré sur le même réseau que la source, il provoque des conflits d'IP (observé), des conflits d'identité SSH et des corruptions de diagnostics. On l'isole (réseau sans la source), on généralise, puis seulement on l'expose.
- **Un clone complet n'est pas automatiquement un template** : il reproduit *toutes* les identités internes de son instance d'origine et porte ses données propres ; un template est préparé (nettoyage des identités, suppression des données d'instance, mécanisme de personnalisation au premier démarrage) pour servir de *référence* à plusieurs instances.

**Validation C : clone démarrable, disque indépendant et diagnostic des identités dupliquées.** ✓

## 6. Image d'OS : capture et réimportation (Partie D — Exercices 7 et 8)

### 6.1 Capture (Exercice 7)

Preuves : [`preuves/07-exercice7-capture.txt`](preuves/07-exercice7-capture.txt), [`preuves/07-fiche-image-os.md`](preuves/07-fiche-image-os.md), [`preuves/capture.sha256`](preuves/capture.sha256), [`preuves/capture-config.xml`](preuves/capture-config.xml)

Après `shutdown` confirmé (`shut off`) et vérification que le chemin de sortie n'existait pas :

```bash
sudo qemu-img convert -p -f qcow2 -O qcow2 "$DISK" "$CAPTURE"
sudo qemu-img check -f qcow2 "$CAPTURE"   # No errors were found on the image (29,48 % alloué)
sudo sha256sum "$CAPTURE" | tee "$HOME/tp1-kvm/preuves/capture.sha256"
```

Somme de contrôle : `1416e8f3d89d7ec37ab29e4127356ba3caeeaf75f7391fbfe76d794d50a5ca64`. La **fiche d'image** complète (distribution/version/archi, date, format/capacité, logiciels, firmware/contrôleurs/réseau, checksum, **statut : capture non généralisée**, comptes présents, procédure de réimportation) : [`preuves/07-fiche-image-os.md`](preuves/07-fiche-image-os.md).

### 6.2 Réimportation (Exercice 8)

Preuve : [`preuves/08-exercice8-reimport.txt`](preuves/08-exercice8-reimport.txt)

L'archive n'a **pas** été démarrée directement : une copie de travail indépendante a été créée (`qemu-img convert CAPTURE → ubuntu-restore01.qcow2`), puis :

```bash
sudo virt-install --connect qemu:///system --name "$RESTORE" --memory 2048 --vcpus 2 \
  --import --disk path="$IMGDIR/$RESTORE.qcow2",format=qcow2,bus=virtio \
  --network network=default,model=virtio \
  --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
  --os-variant "$OSVAR" --graphics vnc,listen=127.0.0.1 --noautoconsole
```

**Résultat attendu confirmé** : la VM `ubuntu-restore01` démarre **sans installation interactive** et retrouve le fichier témoin : `cat /opt/tp1/version.txt` → `Version applicative TP1 : v1` ; `/etc/os-release` → `Ubuntu 24.04.5 LTS` ; hostname `srv-source` ; `machine-id = 03b3f2feab29401fb38c4b77286aa9cb` — **identique à la source**, ce qui est attendu puisque l'image n'a pas été généralisée. La VM a été arrêtée après vérification.

**Questions :**

1. **Pourquoi `--import` remplace l'installation depuis une ISO ?** Le disque contient déjà un système amorçable complet : `--import` attache ce disque comme disque système et démarre directement dessus, sans média d'installation ni phase d'installation (refaire l'installation écraserait le système capturé).
2. **Pourquoi cette capture est-elle une image d'OS et pas un QCOW2 vide ?** Elle contient partitions, OS, logiciels et données (le témoin `/opt/tp1` prouve le contenu réel au démarrage) ; un QCOW2 vide ne contient que la capacité annoncée (4,42 Gio de données réelles ici contre 196 KiB pour un disque vide — voir Partie G).
3. **Éléments nécessaires avec plusieurs disques / NVRAM UEFI / TPM** : capturer chaque disque de manière cohérente (arrêt propre ou snapshot, jamais en cours d'exécution), conserver la **NVRAM UEFI** (variables de boot — ordre/entrées) et l'**état du vTPM** (mesures, secrets) sans lesquels Secure Boot ou des disques chiffrés ne redémarreraient pas ; la fiche doit référencer tous ces artefacts.
4. **Pourquoi ne pas lancer plusieurs copies non généralisées en production ?** Identités dupliquées : machine-id/DUID et état DHCP (conflits d'IP — observé au Partie C), clés SSH hôte identiques (usurpation indétectable), hostname et journaux identiques (diagnostics/faïsseurs), collisions dans les systèmes de monitoring — le tout sans possibilité de discriminer les machines.

**Validation D : image d'OS créée, contrôlée, documentée et testée par démarrage d'une nouvelle VM.** ✓

## 7. Template généralisé (Partie E — Exercice 9)

Preuves : [`preuves/09-exercice9-socle.txt`](preuves/09-exercice9-socle.txt), [`preuves/09-generalisation.txt`](preuves/09-generalisation.txt), [`preuves/09-fiche-template-v1.md`](preuves/09-fiche-template-v1.md), [`preuves/template.sha256`](preuves/template.sha256)

**Socle commun vérifié dans la VM source** (preuve [`preuves/09-exercice9-socle.txt`](preuves/09-exercice9-socle.txt)) : `cloud-init 26.2-0ubuntu1~24.04.2`, `openssh-server`, `qemu-guest-agent` installés ; netplan `50-cloud-init.yaml` = `match: name: "e*"` + `dhcp4: true`, **aucun `macaddress`** (DHCP sans dépendance à la MAC source) ; support NoCloud préparé (`/etc/cloud/cloud.cfg.d/99-z-tp.cfg` : `datasource_list: [NoCloud, None]`, `preserve_hostname: false`, `ssh_deletekeys: true`, `ssh_genkeytypes`) ; `cloud-init clean --logs --seed` exécuté avec succès (la version 26.2 supporte `--seed`), puis `poweroff` — **la source n'a pas été redémarrée entre le nettoyage et la copie**.

**Découverte et correction documentées** : l'autoinstall avait déposé `/etc/cloud/cloud-init.disabled` dans la source (cloud-init désactivé par l'installateur). Conformément au TP (« vérifier aussi que cloud-init n'est pas désactivé… ») et pour ne pas recréer d'état d'instance, ce fichier a été supprimé **hors ligne sur la copie template** avec `virt-customize -a "$TEMPLATE" --delete /etc/cloud/cloud-init.disabled` — jamais sur l'original.

**Généraliser une copie, jamais l'original** :

```bash
sudo virsh domstate "$VM"                       # shut off confirmé
sudo qemu-img convert -p -f qcow2 -O qcow2 "$DISK" "$TEMPLATE"
sudo virt-sysprep --list-operations             # opérations utilisées présentes et explicites
sudo virt-sysprep -a "$TEMPLATE" \
  --operations machine-id,ssh-hostkeys,udev-persistent-net,logfiles,tmp-files,bash-history
sudo qemu-img check -f qcow2 "$TEMPLATE"        # No errors were found
sudo sha256sum "$TEMPLATE" | tee preuves/template.sha256
```

Somme de contrôle du template : `c41241cb1d6a90cf6abe055d4f9480aa49aa7cb287d5a9dae3eeda6079190805` (vérifiée inchangée après déploiement en Partie F : `sha256sum -c` → **OK**).

Interprétation du nettoyage : `machine-id` retire l'identité système pour régénération au premier boot ; `ssh-hostkeys` retire les clés hôte pour régénération (plus d'usurpation possible) ; `udev-persistent-net` nettoie d'anciennes associations réseau (sans garantir le nettoyage de tous les profils Netplan/NetworkManager — ici netplan est propre par construction) ; `logfiles`, `tmp-files`, `bash-history` retirent des traces sélectionnées. Cette liste n'est **pas** une procédure universelle d'effacement des secrets : le compte pédagogique `etudiant` est conservé pour l'accès console et **documenté dans la fiche** (mot de passe `Tp1Kvm2026!`, artefact de laboratoire à ne pas diffuser).

**Validation E : référence distincte de la source, nettoyée, versionnée et prête à être testée.** ✓

## 8. Déploiement de deux VM depuis le template (Partie F — Exercice 10)

Preuves : [`preuves/10-2-app01-copie-seed.txt`](preuves/10-2-app01-copie-seed.txt), [`preuves/10-3-app01-deploiement.txt`](preuves/10-3-app01-deploiement.txt), [`preuves/10-2-app02-copie-seed.txt`](preuves/10-2-app02-copie-seed.txt), [`preuves/10-3-app02-deploiement.txt`](preuves/10-3-app02-deploiement.txt), [`preuves/10-4-generalisation.txt`](preuves/10-4-generalisation.txt)

**10.1** Clé utilisateur dédiée sur l'hôte : `ssh-keygen -t ed25519 -f "$HOME/.ssh/tp1_kvm" -C "tp1-kvm"` (la clé privée reste sur l'hôte, seule la clé publique est placée dans le seed).

**10.2** Par instance (`N=app01` puis `N=app02`) : copie du template (`qemu-img convert TEMPLATE → INSTANCE_DISK`), renouvellement de la graine aléatoire (`sudo virt-sysprep --enable customize -a "$INSTANCE_DISK"` — sortie observée : *« Setting a random seed »* et remise à zéro du machine-id), création de `meta-data` (instance-id distinct) et `user-data` cloud-config (hostname, clés, utilisateur `etudiant` par clé, `/etc/tp-instance`), ISO seed via `genisoimage -volid cidata`, copie vers `/var/lib/libvirt/boot/ubuntu-app0N-seed.iso`.

**10.3** VM créées avec `virt-install --import` + seed cdrom. **Premier démarrage vérifié** : `sudo cloud-init status --wait` → `status: done`, `DataSourceNoCloud [seed=/dev/sr0]`, `errors: []`. Connexion `ssh -i ~/.ssh/tp1_kvm etudiant@IP` fonctionnelle sur les deux instances.

**10.4 — Prouver la généralisation** (valeurs réelles) :

| Vérification | app01 | app02 | Critère → résultat |
|---|---|---|---|
| Nom libvirt et UUID | `ubuntu-app01` / `18ef6164-d25f-46ca-beae-ad4fb68745fb` | `ubuntu-app02` / `0f8ef0b2-84aa-489e-b855-1a4be493d017` | Différents ✓ |
| Disque système | `ubuntu-app01.qcow2` | `ubuntu-app02.qcow2` | Chemins distincts, **sans backing file** ✓ |
| Adresse MAC | `52:54:00:fe:e5:b6` | `52:54:00:83:c5:a5` | Différente ✓ |
| Nom d'hôte Linux | `app01` | `app02` | app01 / app02 ✓ |
| machine-id | `075ec049f0814796ecb58fc5f2850591` | `0001f924494376f79978729ac4e1be8a` | Différents et non vides ✓ |
| Empreinte SSH hôte | `SHA256:bc2m1Qd9rf5Z7qS+dkDph6vuBfmUiiDDvICibrdNJAQ` | `SHA256:3uVkqgPBT5f0RnmqsnQ7xJrrdsf/q19ap0u/ADLqO1U` | Différente ✓ |
| Identité cloud-init | `tp1-ubuntu-app01-v1` | `tp1-ubuntu-app02-v1` | instance-id distinct ✓ |
| Fichier `/etc/tp-instance` | `Instance : app01 — Reference : ubuntu-template-v1` | `Instance : app02 — Reference : ubuntu-template-v1` | Personnalisé ✓ |
| Fichier commun `/opt/tp1/version.txt` | `v1` | `v1` | Même version v1 ✓ |
| Réseau | 192.168.122.41 | 192.168.122.21 | Les deux VM en fonctionnement **simultané** sans conflit ✓ |

Intégrité du template : `sudo sha256sum -c "$HOME/tp1-kvm/preuves/template.sha256"` → **OK** (le template n'a jamais été utilisé comme disque inscriptible).

**Questions :**

1. **Commun vs unique** : commun = OS, logiciels (ssh, cloud-init, agent), config NoCloud, fichier `/opt/tp1/version.txt` v1, matériel virtuel. Unique = UUID libvirt, MAC, machine-id, clés SSH hôte, hostname, instance-id, adresse IP.
2. **Clé publique utilisateur identique mais clés hôte différentes** : la clé publique utilisateur authentifie une *personne* (l'étudiant se connecte partout avec sa clé — voulu). La clé SSH *hôte* identifie *un serveur* : deux serveurs avec la même clé hôte seraient indistinguables pour les clients (usurpation sans alerte, MITM invisible) — d'où la régénération obligatoire à chaque instance.
3. **Nom de VM ≠ hostname** : le nom libvirt est un label de gestion côté hôte (référencé dans le XML) ; le hostname est un état *interne du système invité* écrit par l'OS (ici par cloud-init au premier boot). Changer l'un ne change pas l'autre — c'est précisément le rôle de la personnalisation cloud-init.
4. **Réutilisation du même instance-id** : cloud-init considère l'instance déjà traitée (marqueurs dans `/var/lib/cloud`) et **ne rejoue pas** la personnalisation : hostname, clés, utilisateur, `/etc/tp-instance` resteraient ceux de l'ancienne instance.
5. **Pourquoi ce déploiement est plus adapté à une série de serveurs** : réinstallation inutile (démarrage en ~1 min), identités garanties uniques au premier boot, personnalisation par instance déclarative (seeds), template versionné et vérifiable (sha256), industrialisable en volume — là où le clonage non généralisé duplique toutes les identités et impose un nettoyage manuel et risqué.

**Validation F : deux VM opérationnelles, identités distinctes, logiciels communs conservés et template inchangé.** ✓

## 9. Formats d'images (Partie G — Exercice 11)

Preuve : [`preuves/11-exercice11-formats.txt`](preuves/11-exercice11-formats.txt) — disques **vides** distincts des images d'OS.

| Notion | Sorties réellement obtenues |
|---|---|
| Taille virtuelle | `qemu-img info` : 5 GiB (5 368 709 120 octets) pour les trois images |
| Taille apparente (`ls -lh`) | `disque-raw.img` → **5.0G** ; `disque-qcow2.qcow2` → **193K** |
| Occupation réelle (`du -h`) | `disque-raw.img` → **4.0K** ; `disque-qcow2.qcow2` → **196K** |
| Thin provisioning | Rien n'est alloué à la création (RAW sparse sur ext4 : 4 KiB pour 5 Gio !) — surveiller l'espace reste nécessaire quand le disque se remplit |
| RAW | Format simple sans métadonnées ; peut être sparse selon la création et le FS |
| QCOW2 | Métadonnées, allocation dynamique (196 KiB à la création), backing files et snapshots internes |
| Conversion | `qemu-img convert -p -f raw -O qcow2 disque-raw.img disque-converti.qcow2` → 196 KiB |
| Comparaison | `qemu-img compare -f raw -F qcow2 ...` → **« Images are identical »** : contenu logique égal malgré formats/fichiers différents |

**Questions :**

1. **RAW 5 Gio occupant moins** : le fichier est créé *sparse* sur ext4 — les blocs ne sont alloués qu'au moment des écritures (`du` = 4.0K).
2. **« RAW occupe toujours toute sa capacité » est faux** : démontré ci-dessus (5.0G apparents, 4.0K réels). Un RAW écrit avec des zéros non alloués reste sparse ; seul un remplissage réel consomme les blocs.
3. **QCOW2 ≠ OS installé** : QCOW2 est un format de conteneur (métadonnées d'allocation). Un QCOW2 vide fait ici 196 KiB ; la preuve d'un OS installé est le *contenu* (démarrage effectif, fichiers), pas le format.
4. **Convertir une image ne la généralise pas** : la conversion change le format/le conteneur, pas les identités internes (machine-id, clés hôte, hostname restent) — la généralisation passe par `virt-sysprep`/`cloud-init clean`.
5. **Un template peut-il être stocké en RAW ?** Oui — « template » est un rôle, pas un format ; RAW est amorçable et universellement lisible. Mais on perd les atouts QCOW2 (thin provisioning géré, snapshots internes, backing files) : pour ce TP, QCOW2 est le choix adapté.
6. **Conversion hors ligne** : convertir un disque utilisé par une VM en cours d'exécution donnerait une image incohérente (écritures en vol, cache) ; de plus le verrou de QEMU l'interdit (message `Failed to get shared "write" lock` observé pendant le TP sur un disque actif). D'où l'arrêt préalable systématique.

**Validation G : sorties réelles commentées, sans tailles inventées.** ✓

## 10. Choix de la bonne méthode (Partie H — Exercice 12, études de cas)

Pour chaque cas : **choix**, **justification**, **risque**, **vérification**.

1. **Tester une mise à jour risquée sur une copie d'un serveur existant** — *Choix* : **clone complet** (environnement isolé). *Justification* : reproduction fidèle et indépendante du serveur pour tester sans toucher la production ; un snapshot complète un test local mais n'apporte pas la même indépendance (dépend du disque de la source). *Risque* : identités dupliquées, exposition simultanée au même réseau. *Vérification* : clone sur un réseau isolé, `qemu-img info` sans backing file, table des identités (Partie C), état du firewall avant les tests.
2. **Vingt VM Linux identiques en logiciels, noms et identités distincts** — *Choix* : **template généralisé + personnalisation par instance** (cloud-init NoCloud, comme app01/app02). *Justification* : une seule référence nettoyée et versionnée, identités régénérées au premier boot, déploiement déclaratif et répétable. *Risque* : réutilisation du même instance-id (personnalisation non rejouée), seed mal monté. *Vérification* : `cloud-init status --long` (datasource NoCloud, erreurs vides), machine-id/hostname/clés uniques, `sha256sum -c` du template.
3. **Conserver le système installé d'une VM avant migration** — *Choix* : **image disque cohérente** (capture hors ligne) + configuration XML de la VM et dépendances. *Justification* : l'image conserve partitions/OS/données ; la définition XML décrit le matériel à recréer. *Risque* : capture incohérente si la VM tourne ; perte de NVRAM/NVRAM UEFI/TPM. *Vérification* : **test de restauration obligatoire** (réimport et vérification du témoin — fait en Partie D), checksum comparé.
4. **QCOW2 vide → serveur Ubuntu opérationnel** — *Choix* : **installation depuis une ISO** (ou partir d'une image d'OS compatible). *Justification* : un disque vide n'est pas amorçable « par magie » — l'installateur écrit partitions, bootloader et OS. *Risque* : croire qu'un format suffit ; ISO non vérifiée. *Vérification* : boot sur le disque (plus d'ISO attachée), témoin applicatif, `domblklist`.
5. **Transmettre une base Linux préinstallée et réutilisable à plusieurs équipes** — *Choix* : **template/image généralisée documentée, auditée et versionnée**. *Justification* : il faut un socle commun sans identités ni secrets d'instance, personnalisable à chaque usage. *Risque* : secrets résiduels (comptes, clés, certificats) ; l'effacement sysprep n'est pas universel. *Vérification* : fiche de version (checksum, nettoyages, comptes), audit adapté avant diffusion, test de déploiement.
6. **Restaurer une application à trois disques et une base de données** — *Choix* : **procédure de sauvegarde cohérente de l'ensemble** (données applicatives + BDD + configuration), pas une simple copie du disque système. *Justification* : trois disques + BDD exigent une cohérence applicative (flush/arrêt des services, snapshot orchestré). *Risque* : images prises à des instants différents → restauration incohérente ; secrets/certificats absents. *Vérification* : restauration testée de bout en bout (application qui répond, intégrité BDD), procédure documentée.
7. **Cinq VM temporaires en minimisant le stockage** — *Choix* : **clones liés** à une référence immuable (backing files). *Justification* : chaque overlay ne stocke que ses différences (196 KiB à la création — démontré en approfondissement). *Risque* : dépendance à la chaîne de backing files — la base ne doit plus être modifiée ni supprimée ; déplacer l'overlay seul ne déplace pas la VM. *Vérification* : `qemu-img info --backing-chain`, immutabilité de la base (permissions lecture seule), aplatir (`qemu-img convert`) si besoin d'autonomie.
8. **Nouvelle MAC mais hostname et clé SSH hôte identiques : le clonage a-t-il échoué ?** — *Choix* : **non, pas nécessairement**. *Justification* : les identités *matérielles* (UUID/MAC libvirt) et les identités *internes de l'OS* (machine-id, clés hôte, hostname) ne sont pas renouvelées par les mêmes mécanismes ; `virt-clone` ne renouvelle que le niveau libvirt. *Risque* : croire le clone sain alors qu'il est « jumeau » de la source. *Vérification* : comparer les 7 éléments du tableau de la Partie C puis généraliser (sysprep/cloud-init) avant tout usage réseau.

**Approfondissement facultatif (réalisé)** : overlay `ubuntu-demo-overlay.qcow2` créé sur le template avec `qemu-img create -f qcow2 -F qcow2 -b "$TEMPLATE" "$OVERLAY"` → 196 KiB, chaîne `--backing-chain` documentée ([`preuves/12-facultatif-overlay.txt`](preuves/12-facultatif-overlay.txt)). L'image n'a **pas** été démarrée (personnalisation analogue aux instances requise avant usage).

## 11. Difficultés rencontrées, diagnostic et solution

| # | Difficulté | Diagnostic | Solution |
|---|---|---|---|
| 1 | Paquet `qemu-kvm` « sans candidat » sur Ubuntu 26.10 | Paquet virtuel (message apt) ; `apt-cache policy` | Fournisseur réel = `qemu-system-x86` (1:11.0.3) déjà installé ; tous les outils du TP présents |
| 2 | Autoinstall : `Malformed autoinstall in 'shutdown' section` (installateur bloqué) | Capture d'écran de la console (`virsh screenshot`) montrant l'erreur subiquity | `shutdown: true` → `shutdown: poweroff` (énumération attendue) ; seed reconstruite, réinstallation réussie |
| 3 | Console `virsh console` muette pendant l'installation (TUI subiquity sur la console VGA) | Écran VGA capturé, séries de `start/finish subiquity/...` | Surveillance par `virsh screenshot` + `net-dhcp-leases` (bail = signe de vie) |
| 4 | Source et clone ayant la **même IP** en simultané | `net-dhcp-leases` : deux MAC, une seule IP ; état DHCP copié qui redemande l'adresse + machine-id identique (DUID) | Tests successifs (comme le TP le prévoit) ; leçon documentée au §5 |
| 5 | Script : variables perdues dans des sous-shells (`groupes \| tee`) et commandes `ssh` imbriquées qui consommaient le reste du script (stdin du heredoc) | Sorties tronquées ; analyse du flux | Variables hors des pipelines, `ssh -n`, redirections explicites — rien qui touche au TP lui-même |
| 6 | `/etc/cloud/cloud-init.disabled` présent après autoinstall (cloud-init désactivé par l'installateur) | `test -e` dans la source (le TP demande de vérifier) | Suppression **hors ligne** sur la copie template : `virt-customize --delete` ; la source n'a pas été redémarrée (règle du TP) |
| 7 | `qemu-img info` refuse un disque d'une VM en cours d'exécution | `Failed to get shared "write" lock` | `qemu-img info -U` (lecture seule) ou VM arrêtée — règle du TP respectée |
| 8 | Alerte de clé SSH changeant pour la même IP (VM différentes sur le même bail) | Contexte connu : source/clone/restore partagent le bail 192.168.122.44 | Empreinte vérifiée (`ssh-keygen -lf`) plutôt que supprimer l'alerte — exactement la ligne « dépannage raisonné » du TP |

## 12. Conclusion personnelle

**Je choisis un clone quand** j'ai besoin d'une *copie ponctuelle et fidèle* d'une machine existante (reproduire un environnement pour tester, sauvegarder un état avant une manipulation) — en isolant le réseau et en sachant que les identités internes sont dupliquées jusqu'à généralisation. **Je choisis un template quand** je dois déployer *répétitivement* des serveurs standardisés (série, industrielle, IaC) : une référence nettoyée, versionnée, checksumée, personnalisée à chaque premier démarrage par cloud-init — c'est le seul des trois mécanismes qui garantit des identités uniques par construction. **Je choisis une image quand** je dois *conserver ou transférer* un système installé (migration, archive vérifiable par checksum, réimport ponctuel) — une image capture un état, elle ne promet ni identités uniques ni cohérence applicative : le test de restauration reste obligatoire, et une image seule n'est pas une sauvegarde complète d'un service de production.

Ce TP a permis de produire et de **prouver** chaque étape : VM installée depuis une ISO vérifiée, clone à disque indépendant, capture réimportée et redémarrée, template généralisé puis déployé en deux instances aux identités distinctes et au réseau sans conflit — chaque affirmation de ce rapport s'appuie sur un fichier de preuve joint.

## 13. Validation individuelle finale

- [x] Créer et démarrer une VM (`virt-install`, cycle de vie `virsh`)
- [x] Expliquer le rôle de KVM (accélération noyau), QEMU (machine/périphériques), libvirt (gestion VM/réseaux/stockages)
- [x] Cloner une VM arrêtée et identifier ce qui a été copié (tout le contenu du disque ; MAC/UUID renouvelés)
- [x] Distinguer UUID libvirt, MAC, hostname, machine-id et clé SSH hôte (tableau Partie C)
- [x] Capturer un système installé et le réimporter (Partie D, témoin vérifié)
- [x] Expliquer pourquoi ISO, disque vide et image d'OS ne sont pas équivalents (§2.2, §9, Partie H cas 4)
- [x] Préparer un template sans modifier l'unique copie de la source (copie → sysprep → checksum)
- [x] Déployer deux instances personnalisées sans réinstaller Linux (app01/app02, cloud-init NoCloud)
- [x] Choisir entre clone, template et image selon un besoin concret (Partie H)
- [x] Expliquer les limites d'une image seule comme moyen de sauvegarde (cohérence applicative, test de restauration — cas 6)

## 14. Annexe — arborescence des preuves et reproductibilité

```
TP1/
├── RAPPORT.md                      ← ce compte rendu
├── preuves/                        ← 32 fichiers de preuve (sorties brutes)
│   ├── 01…11-*.txt                 ← sorties des exercices, horodatées
│   ├── source.xml, capture-config.xml, 04-vm01-avant-ejection-iso.xml
│   ├── capture.sha256, template.sha256
│   ├── 07-fiche-image-os.md, 09-fiche-template-v1.md
│   └── capture-console-app01.png, capture-console-app02.png
└── scripts/
    ├── env.sh                      ← variables + helpers du TP
    ├── install-command.sh          ← commande virt-install de la VM source
    ├── vm1-autoinstall-user-data / -meta-data   ← autoinstall srv-source
    └── app01-nocloud-user-data / -meta-data     ← seed NoCloud app01 (identique app02)
```

Reproductibilité : sur un hôte Ubuntu avec KVM/libvirt, copier l'ISO vérifiée dans `/var/lib/libvirt/boot/ubuntu.iso`, sourcer `scripts/env.sh`, puis suivre les commandes des sections 4→9 (les scripts d'autoinstall/NoCloud sont fournis). Les images QCOW2 (volumineuses) restent sur l'hôte conformément au TP : ni clés privées, ni images ne sont déposées dans ce dépôt.
