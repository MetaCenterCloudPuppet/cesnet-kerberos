# == Class kerberos::kprop
#
# kpropd server - the main class.
#
class kerberos::kprop {
  include ::kerberos::kprop::install
  include ::kerberos::kprop::config
  include ::kerberos::kprop::service

  Class['kerberos::kprop::install']
  -> Class['kerberos::kprop::config']
  ~> Class['kerberos::kprop::service']
  -> Class['kerberos::kprop']
}
