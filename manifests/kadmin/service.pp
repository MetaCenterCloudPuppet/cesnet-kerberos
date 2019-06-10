# == Class kerberos::kadmin::service
#
# kadmin server - service.
#
class kerberos::kadmin::service() {
  include ::kerberos::client::config

  $service = $::kerberos::kadmin_service

  if $service {
    service{$service:
      ensure => running,
    }
    if $::kerberos::krb5_conf {
      File[$::kerberos::krb5_conf] ~> Service[$service]
    }
  }

  $touchfile = "${::kerberos::kdc_data_dir}/.puppet-kprop"
  exec{'/usr/local/sbin/kerberos-kprop-all':
    command => "/usr/local/sbin/kerberos-kprop-all && touch ${touchfile}",
    creates => $touchfile,
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
  }
}
