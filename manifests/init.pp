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
  $perform = true,
  $remote_password = undef,
  $remote_principal = undef,
) inherits kerberos::params {
  include ::stdlib

  $_kadmin_hostname = pick($kadmin_hostname, $::fqdn)
  # limitation for easier deployment using Kerberos: kadmin must be KDC
  if $kdc_hostnames and member($kdc_hostnames, $_kadmin_hostname) {
    $_kdc_hostnames = $kdc_hostnames
  } else {
    $_kdc_hostnames = concat([$_kadmin_hostname], pick($kdc_hostnames, []))
  }
  $kprop_hostnames = difference($_kdc_hostnames, [$_kdc_hostnames[0]])

  $_remote_principal = pick($remote_principal, "puppet/admin@${realm}")
  $_acl = concat(["${_remote_principal}	ci	host/*@${realm}"], $acl)

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
        'default_domain' => $::domain,
      },
    },
    'domain_realm' => {
      ".${::domain}" => $realm,
      "${::domain}" => $realm,
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
