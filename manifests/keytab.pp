# == Define kerberos_keytab
#
# Kerberos keytab.
#
# Requires:
#
# * for remote administration: ACL 'aci' on *kerberos::realm* for *kerberos::admin_principal*
#
# Limitations:
#
# * only keytab creation is supported
# * principals must exists (it can be combined with kerberos_principal resource)
#
define kerberos::keytab(
  $principals,
  $owner = undef,
  $group = undef,
  $local = '::undef',
  $mode = undef,
  $wait = 0,
) {
  include ::stdlib
  include ::kerberos

  $path = '/sbin:/usr/sbin:/bin:/usr/bin'

  if $local == '::undef' {
    $is_local = $::fqdn == $::kerberos::_kadmin_hostname
  } else {
    $is_local = $local
  }
  if $::kerberos::admin_principal {
    $args_admin_principal = ['-p', "'${::kerberos::admin_principal}'"]
  } else {
    $args_admin_principal = []
  }
  if $is_local {
    $cmd_list = concat(['kadmin.local'], $args_admin_principal)
  } else {
    if $::kerberos::admin_keytab {
      $args_admin_keytab = ['-k', '-t', "'${::kerberos::admin_keytab}'"]
    } else {
      $args_admin_keytab = []
    }
    if $::kerberos::admin_password {
      $args_admin_password = ['-w', "'${::kerberos::admin_password}'"]
    } else {
      $args_admin_password = []
    }
    $cmd_list = concat(concat(['kadmin'], $args_admin_principal), concat($args_admin_keytab, $args_admin_password))
  }

  if $wait and $wait >= 5 {
    $tries = 1 + $wait / 5
    $try_sleep = 5
  } else {
    $tries = 1
    $try_sleep = 0
  }

  $cmd = join($cmd_list, ' ')
  $all_cmds = prefix($principals, "${cmd} ktadd -k '${title}' ")

  Kerberos_principal <| |>
  -> exec{$all_cmds:
    path      => $path,
    creates   => $title,
    tries     => $tries,
    try_sleep => $try_sleep,
  }
  -> File <| title == $title |>

  if $owner or $group or $mode {
    file{$title:
      owner => $owner,
      group => $group,
      mode  => $mode,
    }
  }
}
