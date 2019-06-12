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
  include ::stdlib
  include ::kerberos

  if $attributes {
    $_attributes = $attributes
  } else {
    $_attributes = $::kerberos::default_attributes
  }
  if $local == '::undef' {
    $is_local = $::fqdn == $::kerberos::_kadmin_hostname
  } else {
    $is_local = $local
  }
  if $policy {
    $_policy = $policy
  } else {
    $_policy = $::kerberos::default_policy
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
    attributes      => $_attributes,
    local           => $is_local,
    password        => $password,
    policy          => $_policy,
  }
}
