# TP2 — Cloud-Init : personnalisation et automatisation des VM

**Module** : Virtualisation et Cloud Computing — Master BD2C (FSAC)
Réutilise l'image généralisée du TP1 (`ubuntu-template-v1.qcow2` → copie de travail `base-cloud.qcow2`, 2,16 Gio) : cloud-init 26.2 + datasource NoCloud déjà configurés.

## Workflow (profils + inventaire + templates Jinja2)

```
        inventaire/vms.yaml                 profiles/*.yaml
   (nom, hostname, cpu, ram, os, profil)    (packages, service, role, …)
                 │                                │
                 └──────────┬─────────────────────┘
                            ▼
              templates/  user-data.j2 + network-config.j2
                            │
                   scripts/generate.py
                            ▼
     output/<vm>/ : user-data, meta-data, network-config + seed-<vm>.iso
                            │
                   scripts/deploy.sh
                            ▼
                     KVM / libvirt (virt-install --import)
```

## Arborescence

```
tp2-cloud-init/
├── images/                  Image de base généralisée (base-cloud.qcow2, conservée sur l'hôte KVM)
├── cloud-init/              Configurations NoCloud de référence (partie I)
│   ├── user-data.yaml           users + clé SSH + ssh_pwauth:false + nginx + motd + runcmd
│   ├── meta-data.yaml           instance-id / local-hostname
│   └── network-config.yaml      format v2 — statique 192.168.122.200/24 (variante DHCP testée d'abord)
├── profiles/
│   ├── web.yaml                 nginx + service nginx + role web
│   ├── database.yaml            postgresql + service + role database
│   └── admin.yaml               htop/tcpdump/tree/ncdu/net-tools + role administration
├── templates/
│   ├── user-data.j2             variables {{ hostname }}, {{ username }}, {{ ssh_public_key }},
│   │                            boucle {% for pkg in packages %}, runcmd conditionnel ({{ service }})
│   └── network-config.j2        interface paramétrable (défaut ens2 relevé sur les VM)
├── inventaire/
│   └── vms.yaml                 vm-web/web01, vm-db/db01, vm-admin/admin01 (nom, cpu, ram, os, profil)
├── scripts/
│   ├── generate.py              rend Jinja2 -> output/ + construit les ISO seed (volid cidata)
│   └── deploy.sh                copies indépendantes de l'image de base + virt-install --import
├── output/                      Artefacts générés (user-data, meta-data, network-config, seed ISO)
│   ├── vm-web/  ├── vm-db/  └── vm-admin/
└── README.md                    Ce fichier
```

## Usage (sur l'hôte KVM)

```bash
# Environnement Python (une fois) : python3 -m venv .venv && ./.venv/bin/pip install Jinja2 PyYAML
./scripts/generate.py                                  # inventaire + profils -> output/ + seeds
./scripts/deploy.sh --dry-run                          # aperçu des commandes de déploiement
./scripts/deploy.sh                                    # déploie les VM de l'inventaire absentes de libvirt
./scripts/deploy.sh --only vm-web                      # une seule VM
```

`deploy.sh` refuse d'écraser un disque existant et ignore les VM déjà définies ; il affiche l'IP (bail DHCP) de chaque VM démarrée.

## Résultats (détails dans le compte rendu local `RAPPORT.md`)

- VM déployées **sans aucune intervention dans les invités** : hostname, utilisateur par clé (`ssh_pwauth: false`, `PasswordAuthentication no`), réseau (DHCP puis statique vérifiée), paquets et services
- Mini-projet déployé simultanément : **web01** (nginx actif, HTTP 200), **db01** (PostgreSQL 16.15 actif), **admin01** (htop 3.3.0, tree 2.1.1) — motd personnalisé par rôle
- Diagnostic : `cloud-init schema` (erreur YAML détectée hors ligne), `analyze show` (durées par étage), cas d'erreur volontaire (`degraded done`, user-data ignoré) corrigé puis instance propre recréée
- Instances déployées pendant la séance : `bd2c-web` (192.168.122.68), `bd2c-db` (.247), `bd2c-admin` (.252) — mêmes configurations que l'inventaire actuel (`vm-web`, `vm-db`, `vm-admin`)
