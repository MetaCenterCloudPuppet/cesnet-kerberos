# == Class kerberos::kdc
#
# KDC Server - the main class.
#
class kerberos::kdc {
  include ::kerberos::kdc::install
  include ::kerberos::kdc::config
  include ::kerberos::kdc::service

  Class['kerberos::kdc::install']
  -> Class['kerberos::kdc::config']
  ~> Class['kerberos::kdc::service']
  -> Class['kerberos::kdc']
}
