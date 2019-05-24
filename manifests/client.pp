# == Class kerberos::client
#
# Kerberos client.
#
class kerberos::client {
  include ::kerberos::client::install
  include ::kerberos::client::config
  include ::kerberos::client::service

  Class['kerberos::client::install']
  -> Class['kerberos::client::config']
  ~> Class['kerberos::client::service']
  -> Class['kerberos::client']
}
