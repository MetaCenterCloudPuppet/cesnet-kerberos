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
}
