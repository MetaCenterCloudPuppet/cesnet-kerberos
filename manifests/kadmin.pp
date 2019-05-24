# == Class kerberos::kadmin
#
# kadmin server - the main class.
#
class kerberos::kadmin {
  include ::kerberos::kadmin::install
  include ::kerberos::kadmin::config
  include ::kerberos::kadmin::service

  Class['kerberos::kadmin::install']
  -> Class['kerberos::kadmin::config']
  ~> Class['kerberos::kadmin::service']
  -> Class['kerberos::kadmin']
}
