# == Class kerberos::kadmin:config
#
# kadmin server - configuration.
#
class kerberos::kadmin::config() {
  include kerberos::client::config
  include kerberos::kdc::config

  if $::kerberos::kdc_conf_dir != $::kerberos::kdc_data_dir {
    file { $::kerberos::kdc_data_dir:
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }
  }

  $acl = $::kerberos::_acl
  file{"${::kerberos::kdc_conf_dir}/kadm5.acl":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('kerberos/kadm5.acl.erb'),
  }

  $kdc_data_dir = $::kerberos::kdc_data_dir
  $kprop_hostnames = $::kerberos::kprop_hostnames
  file{'/usr/local/sbin/kerberos-kprop-all':
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('kerberos/kprop-all.erb'),
  }

  if $::kerberos::master_password {
    exec { 'kdb5_util-create':
      command => "kdb5_util create -s -P ${::kerberos::master_password}",
      path    => '/sbin:/usr/sbin:/bin:/usr/bin',
      # reading /dev/random
      timeout => 0,
      creates => "${::kerberos::kdc_data_dir}/principal",
    }
    if $::kerberos::krb5_conf {
      File[$::kerberos::krb5_conf] -> Exec['kdb5_util-create']
    }
    File[$::kerberos::kdc_conf] -> Exec['kdb5_util-create']
    File[$::kerberos::kdc_data_dir] -> Exec['kdb5_util-create']
    Exec['kdb5_util-create'] -> Exec['kdb5_util-stash']
  }
}
