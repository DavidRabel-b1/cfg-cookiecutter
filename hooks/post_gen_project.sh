#!/usr/bin/env bash

mv environments/kolla/files/overlays/haproxy/haproxy.cfg.{{ cookiecutter.openstack_version }} environments/kolla/files/overlays/haproxy/haproxy.cfg
rm -f environments/kolla/files/overlays/haproxy/haproxy.cfg.*

mkdir secrets
for name in operator configuration; do
    ssh-keygen -t rsa -b 4096 -N "" -f secrets/id_rsa.$name -C ""
done

python scripts/generate-secrets.py
python scripts/set-secrets.py
python scripts/set-ssh-keypairs.py

rm -rf scripts
