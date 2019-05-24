# == Class kerberos::kprop::config
#
# kpropd server - configuration
#
class kerberos::kprop::config() {
  include ::kerberos::kdc::config

  $kadmin_hostname = $::kerberos::_kadmin_hostname
  $realm = $::kerberos::realm

  file { "${::kerberos::kdc_conf_dir}/kpropd.acl":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('kerberos/kpropd.acl.erb'),
    require => File[$::kerberos::kdc_conf_dir],
  }
}
