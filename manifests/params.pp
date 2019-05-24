# == Class kerberos::params
#
# Parameters for Kerberos.
#
class kerberos::params {
  case $::osfamily {
    'Debian': {
      $kadmin_service = 'krb5-admin-server'
      $kdc_service = 'krb5-kdc'
      $kprop_service = 'krb5-kpropd'
    }
    'RedHat': {
      $kadmin_service = 'kadmin'
      $kdc_service = 'krb5kdc'
      $kprop_service = 'kprop'
    }
    default: {
      fail("${::osfamily} (${::operatingsystem}) not supported")
    }
  }

  case $::osfamily {
    'Debian': {
      $kadmin_packages = ['krb5-admin-server']
      $kdc_packages    = ['krb5-kdc']
      $kpropd_packages = ['krb5-kpropd']
      $client_packages = ['krb5-user']
    }
    'RedHat': {
      $kadmin_packages = ['krb5-server']
      $kdc_packages    = ['krb5-server']
      $kpropd_packages = ['krb5-server']
      $client_packages = ['krb5-workstation']
    }
    default: {
      fail("${::osfamily} (${::operatingsystem}) not supported")
    }
  }

  $kdc_conf_dir = $::osfamily ? {
    'debian' => '/etc/krb5kdc',
    'redhat' => '/var/kerberos/krb5kdc',
  }

  $kdc_data_dir = $::osfamily ? {
    'debian' => '/var/lib/krb5kdc',
    'redhat' => '/var/kerberos/krb5kdc',
  }

  $default_krb5_conf = '/etc/krb5.conf'
}
