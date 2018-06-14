---
###################
# Ceph options
####################
# These options must be UUID4 values in string format
# XXXXXXXX-XXXX-4XXX-XXXX-XXXXXXXXXXXX
ceph_cluster_fsid:
ceph_rgw_keystone_password:
# for backward compatible consideration, rbd_secret_uuid is only used for nova,
# cinder_rbd_secret_uuid is used for cinder
rbd_secret_uuid:
cinder_rbd_secret_uuid:

###################
# Database options
####################
database_password:

####################
# Docker options
####################
# This should only be set if you require a password for your Docker registry
docker_registry_password:

######################
# OpenDaylight options
######################
opendaylight_password:

####################
# OpenStack options
####################
aodh_database_password:
aodh_keystone_password:

barbican_database_password:
barbican_keystone_password:
barbican_p11_password:
barbican_crypto_key:

keystone_admin_password:
keystone_database_password:

grafana_database_password:
grafana_admin_password:

glance_database_password:
glance_keystone_password:

gnocchi_database_password:
gnocchi_keystone_password:

karbor_database_password:
karbor_keystone_password:
karbor_openstack_infra_id:

kuryr_keystone_password:

nova_database_password:
nova_api_database_password:
nova_keystone_password:

placement_keystone_password:

neutron_database_password:
neutron_keystone_password:
metadata_secret:

cinder_database_password:
cinder_keystone_password:

cloudkitty_database_password:
cloudkitty_keystone_password:

panko_database_password:
panko_keystone_password:

freezer_database_password:
freezer_keystone_password:

sahara_database_password:
sahara_keystone_password:

designate_database_password:
designate_pool_manager_database_password:
designate_keystone_password:
# This option must be UUID4 value in string format
designate_pool_id:
# This option must be HMAC-MD5 value in string format
designate_rndc_key:

swift_keystone_password:
swift_hash_path_suffix:
swift_hash_path_prefix:

heat_database_password:
heat_keystone_password:
heat_domain_admin_password:

murano_database_password:
murano_keystone_password:
murano_agent_rabbitmq_password:

ironic_database_password:
ironic_keystone_password:

ironic_inspector_database_password:
ironic_inspector_keystone_password:

magnum_database_password:
magnum_keystone_password:

mistral_database_password:
mistral_keystone_password:

trove_database_password:
trove_keystone_password:

ceilometer_database_password:
ceilometer_keystone_password:

watcher_database_password:
watcher_keystone_password:

congress_database_password:
congress_keystone_password:

rally_database_password:

senlin_database_password:
senlin_keystone_password:

solum_database_password:
solum_keystone_password:

horizon_secret_key:
horizon_database_password:

telemetry_secret_key:

manila_database_password:
manila_keystone_password:

octavia_database_password:
octavia_keystone_password:
octavia_ca_password:

searchlight_keystone_password:

tacker_database_password:
tacker_keystone_password:

zun_database_password:
zun_keystone_password:

memcache_secret_key:

#HMAC secret key
osprofiler_secret:

nova_ssh_key:
  private_key:
  public_key:

kolla_ssh_key:
  private_key:
  public_key:

keystone_ssh_key:
  private_key:
  public_key:

bifrost_ssh_key:
  private_key:
  public_key:

####################
# Gnocchi options
####################
gnocchi_project_id:
gnocchi_resource_id:
gnocchi_user_id:

####################
# Qdrouterd options
####################
qdrouterd_password:

####################
# RabbitMQ options
####################
rabbitmq_password:
rabbitmq_cluster_cookie:
outward_rabbitmq_password:
outward_rabbitmq_cluster_cookie:

####################
# HAProxy options
####################
haproxy_password:
keepalived_password:

####################
# Kibana options
####################
kibana_password:

####################
# etcd options
####################
etcd_cluster_token:

####################
# redis options
####################
redis_master_password:

# OSISM specific secrets

prometheus_database_password:
