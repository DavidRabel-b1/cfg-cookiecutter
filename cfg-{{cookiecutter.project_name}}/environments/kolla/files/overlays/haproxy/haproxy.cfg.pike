{% set tls_bind_info = 'ssl crt /etc/haproxy/haproxy.pem' if kolla_enable_tls_external | bool else '' %}
global
  chroot /var/lib/haproxy
  user haproxy
  group haproxy
  daemon
  log {{ api_interface_address }}:{{ fluentd_syslog_port }} local1
  maxconn 4000
  stats socket /var/lib/kolla/haproxy/haproxy.sock
{% if kolla_enable_tls_external | bool %}
  ssl-default-bind-ciphers DEFAULT:!MEDIUM:!3DES
  ssl-default-bind-options no-sslv3 no-tlsv10
  tune.ssl.default-dh-param 4096
{% endif %}

defaults
  log global
  mode http
  option redispatch
  option httplog
  option forwardfor
  retries 3
  timeout http-request 10s
  timeout queue 1m
  timeout connect 10s
  timeout client {{ haproxy_client_timeout }}
  timeout server {{ haproxy_server_timeout }}
  timeout check 10s

listen stats
   bind {{ api_interface_address }}:{{ haproxy_stats_port }}
   mode http
   stats enable
   stats uri /
   stats refresh 15s
   stats realm Haproxy\ Stats
   stats auth {{ haproxy_user }}:{{ haproxy_password }}

{% if enable_rabbitmq | bool %}
listen rabbitmq_management
  bind {{ kolla_internal_vip_address }}:{{ rabbitmq_management_port }}
{% for host in groups['rabbitmq'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ rabbitmq_management_port }} check inter 2000 rise 2 fall 5
{% endfor %}

{% if enable_outward_rabbitmq | bool %}
listen outward_rabbitmq_management
  bind {{ kolla_internal_vip_address }}:{{ outward_rabbitmq_management_port }}
{% for host in groups['outward-rabbitmq'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ outward_rabbitmq_management_port }} check inter 2000 rise 2 fall 5
{% endfor %}

listen outward_rabbitmq_external
  mode tcp
  option tcplog
  timeout client 3600s
  timeout server 3600s
  bind {{ kolla_external_vip_address }}:{{ outward_rabbitmq_port }}
{% for host in groups['outward-rabbitmq'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ outward_rabbitmq_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_mongodb | bool %}
listen mongodb
  bind {{ kolla_internal_vip_address }}:{{ mongodb_port }}
{% for host in groups['mongodb'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ mongodb_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}

{% if enable_keystone | bool %}
listen keystone_internal
  bind {{ kolla_internal_vip_address }}:{{ keystone_public_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['keystone'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ keystone_public_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen keystone_external
  bind {{ kolla_external_vip_address }}:{{ keystone_public_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['keystone'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ keystone_public_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}

listen keystone_admin
  bind {{ kolla_internal_vip_address }}:{{ keystone_admin_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['keystone'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ keystone_admin_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}

{% if enable_glance | bool %}
listen glance_registry
  bind {{ kolla_internal_vip_address }}:{{ glance_registry_port }}
{% for host in groups['glance-registry'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ glance_registry_port }} check inter 2000 rise 2 fall 5
{% endfor %}

listen glance_api
  bind {{ kolla_internal_vip_address }}:{{ glance_api_port }}
  timeout client {{ haproxy_glance_api_client_timeout }}
  timeout server {{ haproxy_glance_api_server_timeout }}
{% for host in groups['glance-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ glance_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen glance_api_external
  bind {{ kolla_external_vip_address }}:{{ glance_api_port }} {{ tls_bind_info }}
  timeout client {{ haproxy_glance_api_client_timeout }}
  timeout server {{ haproxy_glance_api_server_timeout }}
{% for host in groups['glance-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ glance_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_nova | bool %}
listen nova_api
  bind {{ kolla_internal_vip_address }}:{{ nova_api_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['nova-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ nova_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}

listen nova_metadata
  bind {{ kolla_internal_vip_address }}:{{ nova_metadata_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['nova-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ nova_metadata_port }} check inter 2000 rise 2 fall 5
{% endfor %}

listen placement_api
  bind {{ kolla_internal_vip_address }}:{{ placement_api_port }}
  http-request del-header X-Forwarded-Proto
{% for host in groups['placement-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ placement_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}

{% if nova_console == 'novnc' %}
listen nova_novncproxy
  bind {{ kolla_internal_vip_address }}:{{ nova_novncproxy_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['nova-novncproxy'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ nova_novncproxy_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% elif nova_console == 'spice' %}
listen nova_spicehtml5proxy
  bind {{ kolla_internal_vip_address }}:{{ nova_spicehtml5proxy_port }}
{% for host in groups['nova-spicehtml5proxy'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ nova_spicehtml5proxy_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% elif nova_console == 'rdp' %}
listen nova_rdp
  bind {{ kolla_internal_vip_address }}:{{ rdp_port }}
{% for host in groups['hyperv'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {% for ip in hostvars[host]['ansible_ip_addresses'] %}{% if host == ip %}{{ ip }}{% endif %}{% endfor %}:{{ rdp_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}

{% if enable_nova_serialconsole_proxy | bool %}
listen nova_serialconsole_proxy
  bind {{ kolla_internal_vip_address }}:{{ nova_serialproxy_port }}
{% for host in groups['nova-serialproxy'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ nova_serialproxy_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% if haproxy_enable_external_vip | bool %}

listen nova_api_external
  bind {{ kolla_external_vip_address }}:{{ nova_api_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['nova-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ nova_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}

listen nova_metadata_external
  bind {{ kolla_external_vip_address }}:{{ nova_metadata_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['nova-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ nova_metadata_port }} check inter 2000 rise 2 fall 5
{% endfor %}

listen placement_api_external
  bind {{ kolla_external_vip_address }}:{{ placement_api_port }}
  http-request del-header X-Forwarded-Proto
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['placement-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ placement_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}

{% if nova_console == 'novnc' %}
listen nova_novncproxy_external
  bind {{ kolla_external_vip_address }}:{{ nova_novncproxy_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['nova-novncproxy'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ nova_novncproxy_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% elif nova_console == 'spice' %}
listen nova_spicehtml5proxy_external
  bind {{ kolla_external_vip_address }}:{{ nova_spicehtml5proxy_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['nova-spicehtml5proxy'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ nova_spicehtml5proxy_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}

{% if enable_nova_serialconsole_proxy | bool %}
listen nova_serialconsole_proxy_external
  bind {{ kolla_external_vip_address }}:{{ nova_serialproxy_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['nova-serialproxy'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ nova_serialproxy_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}
{% endif %}

{% if enable_neutron | bool %}
listen neutron_server
  bind {{ kolla_internal_vip_address }}:{{ neutron_server_port }}
{% for host in groups['neutron-server'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ neutron_server_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen neutron_server_external
  bind {{ kolla_external_vip_address }}:{{ neutron_server_port }} {{ tls_bind_info }}
{% for host in groups['neutron-server'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ neutron_server_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_horizon | bool %}
listen horizon
  bind {{ kolla_internal_vip_address }}:{{ horizon_port }}
  balance source
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['horizon'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ horizon_port }} check inter 2000 rise 2 fall 5
{% endfor %}

{% if haproxy_enable_external_vip | bool %}
{% if kolla_enable_tls_external | bool %}
listen horizon_external
  bind {{ kolla_external_vip_address }}:443 {{ tls_bind_info }}
  balance source
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['horizon'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ horizon_port }} check inter 2000 rise 2 fall 5
{% endfor %}

frontend horizon_external_redirect
   bind {{ kolla_external_vip_address }}:{{ horizon_port }}
   redirect scheme https code 301 if !{ ssl_fc }
{% else %}
listen horizon_external
  bind {{ kolla_external_vip_address }}:{{ horizon_port }}
{% for host in groups['horizon'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ horizon_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}
{% endif %}

{% if enable_cinder | bool %}
listen cinder_api
  bind {{ kolla_internal_vip_address }}:{{ cinder_api_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['cinder-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ cinder_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen cinder_api_external
  bind {{ kolla_external_vip_address }}:{{ cinder_api_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['cinder-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ cinder_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_cloudkitty | bool %}
listen cloudkitty_api
  bind {{ kolla_internal_vip_address }}:{{ cloudkitty_api_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['cloudkitty-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ cloudkitty_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen cloudkitty_api_external
  bind {{ kolla_external_vip_address }}:{{ cloudkitty_api_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['cloudkitty-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ cloudkitty_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_octavia | bool %}
listen octavia_api
  bind {{ kolla_internal_vip_address }}:{{ octavia_api_port }}
  http-request del-header X-Forwarded-Proto
{% for host in groups['octavia-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ octavia_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}

{% if haproxy_enable_external_vip | bool %}
listen octavia_api_external
  bind {{ kolla_external_vip_address }}:{{ octavia_api_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['octavia-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ octavia_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_panko | bool %}
listen panko_api
  bind {{ kolla_internal_vip_address }}:{{ panko_api_port }}
  http-request del-header X-Forwarded-Proto
{% for host in groups['panko-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ panko_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen panko_api_external
  bind {{ kolla_external_vip_address }}:{{ panko_api_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['panko-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ panko_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_heat | bool %}
listen heat_api
  bind {{ kolla_internal_vip_address }}:{{ heat_api_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['heat-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ heat_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}

listen heat_api_cfn
  bind {{ kolla_internal_vip_address }}:{{ heat_api_cfn_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['heat-api-cfn'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ heat_api_cfn_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen heat_api_external
  bind {{ kolla_external_vip_address }}:{{ heat_api_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['heat-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ heat_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}

listen heat_api_cfn_external
  bind {{ kolla_external_vip_address }}:{{ heat_api_cfn_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['heat-api-cfn'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ heat_api_cfn_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_grafana | bool %}
listen grafana_server
  bind {{ kolla_internal_vip_address }}:{{ grafana_server_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['grafana'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ grafana_server_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen grafana_server_external
  bind {{ kolla_external_vip_address }}:{{ grafana_server_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['grafana'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ grafana_server_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_ironic | bool %}
listen ironic_api
  bind {{ kolla_internal_vip_address }}:{{ ironic_api_port }}
{% for host in groups['ironic-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ ironic_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
listen ironic_inspector
  bind {{ kolla_internal_vip_address }}:{{ ironic_inspector_port }}
{% for host in groups['ironic-inspector'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ ironic_inspector_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen ironic_api_external
  bind {{ kolla_external_vip_address }}:{{ ironic_api_port }} {{ tls_bind_info }}
{% for host in groups['ironic-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ ironic_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
listen ironic_inspector_external
  bind {{ kolla_external_vip_address }}:{{ ironic_inspector_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['ironic-inspector'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ ironic_inspector_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_karbor | bool %}
listen karbor_api
  bind {{ kolla_internal_vip_address }}:{{ karbor_api_port }}
{% for host in groups['karbor-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ karbor_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen karbor_api_external
  bind {{ kolla_external_vip_address }}:{{ karbor_api_port }} {{ tls_bind_info }}
{% for host in groups['karbor-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ karbor_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}


{% if enable_freezer | bool %}
listen freezer_api
  bind {{ kolla_internal_vip_address }}:{{ freezer_api_port }}
{% for host in groups['freezer-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ freezer_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen freezer_api_external
  bind {{ kolla_external_vip_address }}:{{ freezer_api_port }} {{ tls_bind_info }}
{% for host in groups['freezer-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ freezer_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}


{% if enable_senlin | bool %}
listen senlin_api
  bind {{ kolla_internal_vip_address }}:{{ senlin_api_port }}
{% for host in groups['senlin-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ senlin_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen senlin_api_external
  bind {{ kolla_external_vip_address }}:{{ senlin_api_port }} {{ tls_bind_info }}
{% for host in groups['senlin-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ senlin_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_solum | bool %}
listen solum_application_deployment
  bind {{ kolla_internal_vip_address }}:{{ solum_application_deployment_port }}
{% for host in groups['solum-application-deployment'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ solum_application_deployment_port }} check inter 2000 rise 2 fall 5
{% endfor %}

listen solum_image_builder
  bind {{ kolla_internal_vip_address }}:{{ solum_image_builder_port }}
{% for host in groups['solum-image-builder'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ solum_image_builder_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen solum_application_deployment_external
  bind {{ kolla_external_vip_address }}:{{ solum_application_deployment_port }} {{ tls_bind_info }}
{% for host in groups['solum-application-deployment'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ solum_application_deployment_port }} check inter 2000 rise 2 fall 5
{% endfor %}

listen solum_image_builder_external
  bind {{ kolla_external_vip_address }}:{{ solum_image_builder_port }} {{ tls_bind_info }}
{% for host in groups['solum-image-builder'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ solum_image_builder_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_swift | bool %}
listen swift_api
  bind {{ kolla_internal_vip_address }}:{{ swift_proxy_server_port }}
{% for host in groups['swift-proxy-server'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ swift_proxy_server_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen swift_api_external
  bind {{ kolla_external_vip_address }}:{{ swift_proxy_server_port }} {{ tls_bind_info }}
{% for host in groups['swift-proxy-server'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ swift_proxy_server_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_murano | bool %}
listen murano_api
  bind {{ kolla_internal_vip_address }}:{{ murano_api_port }}
{% for host in groups['murano-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ murano_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen murano_api_external
  bind {{ kolla_external_vip_address }}:{{ murano_api_port }} {{ tls_bind_info }}
{% for host in groups['murano-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ murano_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_manila | bool %}
listen manila_api
  bind {{ kolla_internal_vip_address }}:{{ manila_api_port }}
{% for host in groups['manila-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ manila_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen manila_api_external
  bind {{ kolla_external_vip_address }}:{{ manila_api_port }} {{ tls_bind_info }}
{% for host in groups['manila-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ manila_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_magnum | bool %}
listen magnum_api
  bind {{ kolla_internal_vip_address }}:{{ magnum_api_port }}
{% for host in groups['magnum-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ magnum_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen magnum_api_external
  bind {{ kolla_external_vip_address }}:{{ magnum_api_port }} {{ tls_bind_info }}
{% for host in groups['magnum-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ magnum_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_watcher | bool and enable_ceilometer | bool %}
listen watcher_api
  bind {{ kolla_internal_vip_address }}:{{ watcher_api_port }}
{% for host in groups['watcher-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ watcher_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen watcher_api_external
  bind {{ kolla_external_vip_address }}:{{ watcher_api_port }} {{ tls_bind_info }}
{% for host in groups['watcher-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ watcher_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_sahara | bool %}
listen sahara_api
  bind {{ kolla_internal_vip_address }}:{{ sahara_api_port }}
{% for host in groups['sahara-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ sahara_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen sahara_api_external
  bind {{ kolla_external_vip_address }}:{{ sahara_api_port }} {{ tls_bind_info }}
{% for host in groups['sahara-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ sahara_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_searchlight | bool %}
listen searchlight_api
  bind {{ kolla_internal_vip_address }}:{{ searchlight_api_port }}
{% for host in groups['searchlight-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ searchlight_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen searchlight_api_external
  bind {{ kolla_external_vip_address }}:{{ searchlight_api_port }} {{ tls_bind_info }}
{% for host in groups['searchlight-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ searchlight_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_ceph | bool and enable_ceph_rgw | bool %}
listen radosgw
  bind {{ kolla_internal_vip_address }}:{{ rgw_port }}
{% for host in groups['ceph-rgw'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ rgw_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen radosgw_external
  bind {{ kolla_external_vip_address }}:{{ rgw_port }} {{ tls_bind_info }}
{% for host in groups['ceph-rgw'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ rgw_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_kibana | bool %}

userlist kibanauser
  user {{ kibana_user }} insecure-password {{ kibana_password }}

listen kibana
  bind {{ kolla_internal_vip_address }}:{{ kibana_server_port }}
  acl auth_acl http_auth(kibanauser)
  http-request auth realm basicauth unless auth_acl
{% for host in groups['kibana'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ kibana_server_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen kibana_external
  bind {{ kolla_external_vip_address }}:{{ kibana_server_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
  acl auth_acl http_auth(kibanauser)
  http-request auth realm basicauth unless auth_acl
{% for host in groups['kibana'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ kibana_server_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_gnocchi | bool %}
listen gnocchi_api
  bind {{ kolla_internal_vip_address }}:{{ gnocchi_api_port }}
{% for host in groups['gnocchi-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ gnocchi_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen gnocchi_api_external
  bind {{ kolla_external_vip_address }}:{{ gnocchi_api_port }} {{ tls_bind_info }}
{% for host in groups['gnocchi-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ gnocchi_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_elasticsearch | bool %}
listen elasticsearch
  option dontlog-normal
  bind {{ kolla_internal_vip_address }}:{{ elasticsearch_port }}
{% for host in groups['elasticsearch'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ elasticsearch_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}

{% if enable_barbican | bool %}
listen barbican_api
  bind {{ kolla_internal_vip_address }}:{{ barbican_api_port }}
{% for host in groups['barbican-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ barbican_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen barbican_api_external
  bind {{ kolla_external_vip_address }}:{{ barbican_api_port }} {{ tls_bind_info }}
{% for host in groups['barbican-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ barbican_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_aodh | bool %}
listen aodh_api
  bind {{ kolla_internal_vip_address }}:{{ aodh_api_port }}
{% for host in groups['aodh-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ aodh_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen aodh_api_external
  bind {{ kolla_external_vip_address }}:{{ aodh_api_port }} {{ tls_bind_info }}
{% for host in groups['aodh-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ aodh_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_trove | bool %}
listen trove_api
  bind {{ kolla_internal_vip_address }}:{{ trove_api_port }}
{% for host in groups['trove-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ trove_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen trove_api_external
  bind {{ kolla_external_vip_address }}:{{ trove_api_port }} {{ tls_bind_info }}
{% for host in groups['trove-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ trove_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_congress | bool %}
listen congress_api
  bind {{ kolla_internal_vip_address }}:{{ congress_api_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['congress-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ congress_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen congress_api_external
  bind {{ kolla_external_vip_address }}:{{ congress_api_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['congress-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ congress_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_designate | bool %}
listen designate_api
  bind {{ kolla_internal_vip_address }}:{{ designate_api_port }}
{% for host in groups['designate-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ designate_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen designate_api_external
  bind {{ kolla_external_vip_address }}:{{ designate_api_port }} {{ tls_bind_info }}
{% for host in groups['designate-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ designate_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_mistral | bool %}
listen mistral_api
  bind {{ kolla_internal_vip_address }}:{{ mistral_api_port }}
{% for host in groups['mistral-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ mistral_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen mistral_api_external
  bind {{ kolla_external_vip_address }}:{{ mistral_api_port }} {{ tls_bind_info }}
{% for host in groups['mistral-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ mistral_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_tacker | bool %}
listen tacker_server
  bind {{ kolla_internal_vip_address }}:{{ tacker_server_port }}
{% for host in groups['tacker'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ tacker_server_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen tacker_server_external
  bind {{ kolla_external_vip_address }}:{{ tacker_server_port }} {{ tls_bind_info }}
{% for host in groups['tacker'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ tacker_server_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_zun | bool %}
listen zun_api
  bind {{ kolla_internal_vip_address }}:{{ zun_api_port }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
{% for host in groups['zun-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ zun_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen zun_api_external
  bind {{ kolla_external_vip_address }}:{{ zun_api_port }} {{ tls_bind_info }}
  http-request del-header X-Forwarded-Proto if { ssl_fc }
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
{% for host in groups['zun-api'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ zun_api_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

{% if enable_skydive | bool %}
listen skydive_server
  bind {{ kolla_internal_vip_address }}:{{ skydive_analyzer_port }}
{% for host in groups['skydive-analyzer'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ skydive_analyzer_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% if haproxy_enable_external_vip | bool %}

listen skydive_server_external
  bind {{ kolla_external_vip_address }}:{{ skydive_analyzer_port }} {{ tls_bind_info }}
{% for host in groups['skydive-analyzer'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ skydive_analyzer_port }} check inter 2000 rise 2 fall 5
{% endfor %}
{% endif %}
{% endif %}

# (NOTE): This defaults section deletes forwardfor as recommended by:
#         https://marc.info/?l=haproxy&m=141684110710132&w=1

defaults
  log global
  mode http
  option redispatch
  option httplog
  retries 3
  timeout http-request 10s
  timeout queue 1m
  timeout connect 10s
  timeout client 1m
  timeout server 1m
  timeout check 10s

{% if enable_mariadb | bool %}
listen mariadb
  mode tcp
  timeout client 3600s
  timeout server 3600s
  option tcplog
  option tcpka
  option mysql-check user haproxy post-41
  bind {{ kolla_internal_vip_address }}:{{ mariadb_port }}
{% for host in groups['mariadb'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ mariadb_port }} check inter 2000 rise 2 fall 5 {% if not loop.first %}backup{% endif %}

{% endfor %}
{% endif %}

{% if enable_opendaylight | bool %}
listen opendaylight_api
  bind {{ kolla_internal_vip_address }}:{{ opendaylight_haproxy_restconf_port }}
  balance source
{% for host in groups['opendaylight'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ opendaylight_restconf_port }} check fall 5 inter 2000 rise 2
{% endfor %}

listen opendaylight_api_backup
  bind {{ kolla_internal_vip_address }}:{{ opendaylight_haproxy_restconf_port_backup }}
  balance source
{% for host in groups['opendaylight'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:{{ opendaylight_restconf_port_backup }} check fall 5 inter 2000 rise 2
{% endfor %}

{% endif %}

# OSISM specific configuration

listen ceph_dashboard
  bind {{ kolla_internal_vip_address }}:7000
{% for host in groups['ceph-mgr'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:7000 check inter 2000 rise 2 fall 5
{% endfor %}

listen ceph_proemtheus
  bind {{ kolla_internal_vip_address }}:9283
{% for host in groups['ceph-mgr'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:9283 check inter 2000 rise 2 fall 5
{% endfor %}

listen prometheus
  bind {{ kolla_internal_vip_address }}:9090
{% for host in groups['prometheus'] %}
  server {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_' + hostvars[host]['api_interface']]['ipv4']['address'] }}:9090 check inter 2000 rise 2 fall 5
{% endfor %}
