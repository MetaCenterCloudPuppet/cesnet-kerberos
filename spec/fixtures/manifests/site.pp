class { '::kerberos':
  master_password => 'good-password',
  perform         => false,
  realm           => 'MONKEY_ISLANDS',
  admin_password  => 'good-password',
}
