# == Class kerberos
#
# Main configuration class for Kerberos.
#
class kerberos(
  $realm,
  $acl = [],
  $client_packages = $::kerberos::params::client_packages,
  $client_properties = undef,
  $kadmin_service = $::kerberos::params::kadmin_service,
  $kadmin_packages = $::kerberos::params::kadmin_packages,
  $kadmin_hostname = undef,
  $kdc_conf = "${::kerberos::kdc_conf_dir}/kdc.conf",
  $kdc_service = $::kerberos::params::kdc_service,
  $kdc_packages = $::kerberos::params::kdc_packages,
  $kdc_hostnames = undef,
  $kdc_properties = undef,
  $krb5_conf = $::kerberos::params::default_krb5_conf,
  $master_password = undef,
  $admin_keytab = undef,
  $admin_password = undef,
  $admin_principal = undef,
  $domain = $::domain,
  $default_attributes = undef,
  $default_policy = undef,
  $perform = true,
) inherits kerberos::params {
  include ::stdlib

  $_kadmin_hostname = pick($kadmin_hostname, $::fqdn)
  $_kdc_hostnames = pick($kdc_hostnames, [$_kadmin_hostname])
  $kprop_hostnames = difference($_kdc_hostnames, [$_kadmin_hostname])

  if $admin_principal {
    $admin_acl = [
      "${admin_principal}	admcil	*/*@${realm}",
      "${admin_principal}	admcil	*@${realm}",
      "${admin_principal}	admcil	*",
    ]
  } else {
    $admin_acl = []
  }
  $_acl = concat($admin_acl, $acl)

  $_client_properties = deep_merge({
    'libdefaults' => {
      'default_realm' => $realm,
      'dns_lookup' => 'no',
      'dns_lookup_realm' => 'no',
      'dns_fallback' => 'no',
    },
    'realms' => {
      "${realm}" => {
        'kdc' => $_kdc_hostnames,
        'admin_server' => $_kadmin_hostname,
        'default_domain' => $domain,
      },
    },
    'domain_realm' => {
      ".${domain}" => $realm,
      "${domain}" => $realm,
    },
  }, $client_properties)
  $_kdc_properties = deep_merge({
    'kdcdefaults' => {
      'kdc_ports' => '88',
    },
    'realms' => {
      "${realm}" => {
        'database_name' => "${::kerberos::kdc_data_dir}/principal",
        'acl_file' => "${::kerberos::kdc_conf_dir}/kadm5.acl",
        #'key_stash_file' => '/etc/krb5kdc/stash',
        # aes256-sha2 aes128-sha2
        'supported_enctypes' => 'aes256-sha1:normal aes128-sha1:normal des3-cbc-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal',
        #'default_principal_flags' => '+preauth',
      },
    },
  }, $kdc_properties)

  if $perform {
    if $::fqdn == $_kadmin_hostname {
      include ::kerberos::kadmin
    }
    if member($_kdc_hostnames, $::fqdn) {
      include ::kerberos::kdc
    }
    if member($kprop_hostnames, $::fqdn) {
      include ::kerberos::kprop
    }
    include ::kerberos::client
  }
}
