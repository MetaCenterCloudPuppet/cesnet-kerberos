# == Define principal
#
# Kerberos principal. Wrapper around kerberos_principal using parameters from the main kerberos class.
#
# Requires:
#
# * for remote administration:
#  * ACL 'aci' on *kerberos::realm* for *kerberos::admin_principal*
#  * admin principal created
#
define kerberos::principal(
  $ensure = 'present',
  $attributes = undef,
  $local = '::undef',
  $password = undef,
  $policy = undef,
) {
  include ::kerberos

  if $local == '::undef' {
    $is_local = $::fqdn == $::kerberos::_kadmin_hostname
  } else {
    $is_local = $local
  }

  if $is_local {
    $admin_keytab = undef
    $admin_password = undef
    $admin_principal = undef
  } else {
    $admin_keytab = $::kerberos::admin_keytab
    $admin_password = $::kerberos::admin_password
    $admin_principal = $::kerberos::admin_principal
  }

  kerberos_principal{$title:
    ensure          => $ensure,
    admin_keytab    => $admin_keytab,
    admin_password  => $admin_password,
    admin_principal => $admin_principal,
    attributes      => $attributes,
    local           => $is_local,
    password        => $password,
    policy          => $policy,
  }
}
