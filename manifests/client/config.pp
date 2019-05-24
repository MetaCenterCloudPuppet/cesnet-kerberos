# == Class kerberos::client::config
#
# Kerberos client setup - config.
#
class kerberos::client::config {
  $properties = $::kerberos::_client_properties

  if ($::kerberos::krb5_conf) {
    file { $::kerberos::krb5_conf:
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('kerberos/conf.erb'),
    }
  }
}
