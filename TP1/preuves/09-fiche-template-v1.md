# Fiche template-v1 — ubuntu-template-v1.qcow2

| Champ | Valeur |
|---|---|
| OS / architecture / date | Ubuntu Server 24.04.5 LTS (noble), amd64, 2026-11-10 |
| Logiciels communs | openssh-server, cloud-init 26.2, qemu-guest-agent, config NoCloud (99-z-tp.cfg), netplan DHCP sans MAC |
| Firmware / materiel attendus | BIOS SeaBIOS, disque VirtIO (vda), reseau VirtIO NAT default, canal virtio guest-agent, 2 vCPU / 2 Go RAM / 15 Gio |
| Nettoyage effectue | virt-sysprep : machine-id, ssh-hostkeys, udev-persistent-net, logfiles, tmp-files, bash-history + suppression hors ligne de /etc/cloud/cloud-init.disabled + cloud-init clean --logs --seed prealable dans la VM de construction |
| Comptes conserves | Compte "etudiant" (pedagogique, mot de passe Tp1Kvm2026!, sudo NOPASSWD) — artefact de laboratoire, ne pas diffuser ; les instances recreent etudiant via cloud-init |
| Personnalisation 1er demarrage | cloud-init NoCloud (seed cidata) : hostname, instance-id, cles SSH hote regenerees, utilisateur etudiant par cle, /etc/tp-instance |
| Somme de controle | c41241cb1d6a90cf6abe055d4f9480aa49aa7cb287d5a9dae3eeda6079190805 |
| Resultats des tests de deploiement | A renseigner apres Partie F : app01/app02 deployees, identites distinctes |
