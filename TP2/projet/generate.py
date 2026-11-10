from pathlib import Path
import yaml
from jinja2 import Environment, FileSystemLoader

root = Path(__file__).resolve().parent
inventory = yaml.safe_load((root/'inventory/vms.yml').read_text())
env = Environment(loader=FileSystemLoader(root/'templates'), autoescape=False)
template = env.get_template('user-data.j2')
key = Path.home().joinpath('.ssh/bd2c_tp2.pub').read_text().strip()

for vm in inventory['vms']:
    profile = yaml.safe_load((root/f"profiles/{vm['profile']}.yml").read_text())
    target = root/'generated'/vm['name']
    target.mkdir(parents=True, exist_ok=True)
    (target/'user-data').write_text(template.render(**vm, **profile, ssh_public_key=key))
    (target/'meta-data').write_text(f"instance-id: iid-{vm['name']}\nlocal-hostname: {vm['hostname']}\n")
    print(target)
