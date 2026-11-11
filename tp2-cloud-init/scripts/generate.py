#!/usr/bin/env python3
"""generate.py — TP2 : workflow « inventaire + profils + templates Jinja2 ».

Pour chaque VM de l'inventaire, produit dans output/ :
  - user-data        (rendu de templates/user-data.j2 : inventaire + profil + clé publique)
  - meta-data        (instance-id unique + local-hostname)
  - network-config   (rendu de templates/network-config.j2)
  - seed-<name>.iso  (ISO NoCloud volid « cidata » : user-data + meta-data + network-config)

Usage :
  ./generate.py [--inventory inventaire/vms.yaml]

Prérequis : python3-venv, Jinja2, PyYAML (see README), genisoimage.
"""
import argparse
import subprocess
from pathlib import Path

import yaml
from jinja2 import Environment, FileSystemLoader

ROOT = Path(__file__).resolve().parent.parent  # racine tp2-cloud-init


def main() -> None:
    parser = argparse.ArgumentParser(description="Générer les configurations cloud-init des VM")
    parser.add_argument("--inventory", default="inventaire/vms.yaml",
                        help="chemin de l'inventaire YAML (relatif à tp2-cloud-init)")
    args = parser.parse_args()

    inventory = yaml.safe_load((ROOT / args.inventory).read_text())
    env = Environment(loader=FileSystemLoader(ROOT / "templates"), autoescape=False)
    template_user = env.get_template("user-data.j2")
    template_net = env.get_template("network-config.j2")
    key = Path.home().joinpath(".ssh/bd2c_tp2.pub").read_text().strip()

    for vm in inventory["vms"]:
        profile = yaml.safe_load(
            (ROOT / f"profiles/{vm['profile']}.yaml").read_text())
        target = ROOT / "output" / vm["name"]
        target.mkdir(parents=True, exist_ok=True)

        (target / "user-data").write_text(
            template_user.render(**vm, **profile, ssh_public_key=key))
        (target / "meta-data").write_text(
            f"instance-id: iid-{vm['name']}\nlocal-hostname: {vm['hostname']}\n")
        (target / "network-config").write_text(
            template_net.render(**vm, **profile))

        seed = ROOT / "output" / f"seed-{vm['name']}.iso"
        subprocess.run(
            ["genisoimage", "-output", str(seed), "-volid", "cidata",
             "-joliet", "-rock",
             str(target / "user-data"), str(target / "meta-data"),
             str(target / "network-config")],
            check=True, stdout=subprocess.DEVNULL)
        print(f"{target}  +  {seed.name}")


if __name__ == "__main__":
    main()
