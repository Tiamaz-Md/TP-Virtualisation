# Fiche d'image OS — ubuntu-os-capture-v1.qcow2

| Champ | Valeur |
|---|---|
| Distribution / version / archi | Ubuntu Server 24.04.5 LTS (noble), amd64 (x86_64) |
| Date de capture | 2026-11-10 21:10 UTC (hote tmz, VMware Workstation) |
| Identifiant de version | v1 — fichier temoin /opt/tp1/version.txt : "Version applicative TP1 : v1" |
| Format / capacite virtuelle | QCOW2 (compat 1.1), 15 Gio virtuels, occupation reelle 4,42 Gio |
| Logiciels installés | Ubuntu Server minimal, openssh-server, cloud-init, qemu-guest-agent |
| Rôle prévu | Serveur source de reference (TP1) : reproduction pour test, capture, template |
| Firmware | BIOS (SeaBIOS 1.17.0-debian), boot hd, pas de TPM/Secure Boot |
| Controleurs | Disque VirtIO (vda), reseau VirtIO sur NAT libvirt default (virbr0), canal virtio org.qemu.guest_agent.0 |
| Somme de controle | 1416e8f3d89d7ec37ab29e4127356ba3caeeaf75f7391fbfe76d794d50a5ca64 |
| Statut | **Capture NON GENERALISEE** (machine-id, hostname, cles SSH hote conserves) |
| Comptes / donnees | Compte local "etudiant" (mot de passe pedagogique Tp1Kvm2026!, sudo NOPASSWD ajoute pour le TP) ; cle publique hote autorisee ; aucun secret personnel |
| Procédure de réimportation | 1) qemu-img convert -f qcow2 -O qcow2 capture.qcow2 disque-travail.qcow2 (copie de travail) 2) virt-install --import --disk disque-travail.qcow2 --network network=default --os-variant ubuntu24.04 3) verifier /opt/tp1/version.txt au boot |
