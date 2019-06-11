# == Define policy
#
# Kerberos policy. Wrapper around kerberos_policy using parameters from the main kerberos class.
#
# Requires:
#
# * for remote administration:
#  * ACL 'aci' on *kerberos::realm* for *kerberos::admin_principal*
#  * admin principal created
#
define kerberos::policy(
  $ensure = 'present',
  $local = '::undef',
  $maxlife = undef,
  $minlength = undef,
  $minclasses = undef,
  $history = undef,
  $maxfailure = undef,
  $failurecountinterval = undef,
  $lockoutduration = undef,
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

  kerberos_policy{$title:
    ensure               => $ensure,
    admin_keytab         => $admin_keytab,
    admin_password       => $admin_password,
    admin_principal      => $admin_principal,
    local                => $is_local,
    maxlife              => $maxlife,
    minlength            => $minlength,
    minclasses           => $minclasses,
    history              => $history,
    maxfailure           => $maxfailure,
    failurecountinterval => $failurecountinterval,
    lockoutduration      => $lockoutduration,
  }
}
