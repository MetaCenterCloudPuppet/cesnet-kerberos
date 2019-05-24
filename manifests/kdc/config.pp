# == Class kerberos::kdc::config
#
# KDC Server - configuration.
#
class kerberos::kdc::config {
  include ::stdlib
  include kerberos::client::config

  $properties = $::kerberos::_kdc_properties

  file { $::kerberos::kdc_conf_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }
  -> file { $::kerberos::kdc_conf:
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('kerberos/conf.erb'),
  }
  if $::kerberos::master_password {
    exec { 'kdb5_util-stash':
      command => "kdb5_util stash -P ${::kerberos::master_password}",
      path    => '/sbin:/usr/sbin:/bin:/usr/bin',
      creates => "${::kerberos::kdc_conf_dir}/.k5.${::kerberos::realm}",
    }
    if $::kerberos::krb5_conf {
      File[$::kerberos::krb5_conf] -> Exec['kdb5_util-stash']
    }
    File[$::kerberos::kdc_conf] -> Exec['kdb5_util-stash']
    File[$::kerberos::kdc_conf_dir] -> Exec['kdb5_util-stash']
  }
}
