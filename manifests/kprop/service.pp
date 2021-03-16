# == Class kerberos::kprop::service
#
# kpropd server - service.
#
class kerberos::kprop::service() {
  include ::kerberos::client::config
  include ::kerberos::kdc::config

  $service = $::kerberos::kprop_service

  if $service {
    service{$service:
      enable => true,
      ensure => running,
    }
    if $::kerberos::krb5_conf {
      File[$::kerberos::krb5_conf] ~> Service[$service]
    }
    File[$::kerberos::kdc_conf] ~> Service[$service]
  }
}
