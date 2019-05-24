# == Class kerberos::kdc::install
#
# KDC Server - installation.
#
class kerberos::kdc::service {
  include ::stdlib
  include ::kerberos::client::config

  $service = $::kerberos::kdc_service

  if $service {
    service{$service:
      ensure => running,
    }
    if $::kerberos::krb5_conf {
      File[$::kerberos::krb5_conf] ~> Service[$service]
    }
  }
}
