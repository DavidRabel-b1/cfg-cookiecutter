#!/usr/bin/env python

from ruamel.yaml import YAML

SECRETS_ALL = {
    'keystone_admin_password': 'keystone_admin_password'
}

SECRETS_MONITORING = {
    'monitoring_grafana_password': 'grafana_admin_password',
    'prometheus_exporter_haproxy_target_password': 'haproxy_password',
    'prometheus_exporter_mariadb_target_password': 'prometheus_database_password'
}

SECRETSFILE_INPUT = 'environments/kolla/secrets.yml'
SECRETSFILE_OUTPUT_ALL = 'environments/secrets.yml'
SECRETSFILE_OUTPUT_MONITORING = 'environments/monitoring/secrets.yml'

yaml = YAML()
yaml.explicit_start = True

with open(SECRETSFILE_INPUT) as fp:
    secrets_input = yaml.load(open(SECRETSFILE_INPUT))

with open(SECRETSFILE_OUTPUT_ALL) as fp:
    secrets_output_all = yaml.load(open(SECRETSFILE_OUTPUT_ALL))

with open(SECRETSFILE_OUTPUT_MONITORING) as fp:
    secrets_output_monitoring = yaml.load(open(SECRETSFILE_OUTPUT_MONITORING))

for key in SECRETS_MONITORING.keys():
    secrets_output_monitoring[key] = secrets_input[SECRETS_MONITORING[key]]

for key in SECRETS_ALL.keys():
    secrets_output_all[key] = secrets_input[SECRETS_ALL[key]]

with open(SECRETSFILE_OUTPUT_ALL, 'w+') as fp:
    yaml.dump(secrets_output_all, fp)

with open(SECRETSFILE_OUTPUT_MONITORING, 'w+') as fp:
    yaml.dump(secrets_output_monitoring, fp)
