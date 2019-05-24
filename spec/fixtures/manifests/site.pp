class { '::kerberos':
  master_password => 'good-password',
  perform         => false,
  realm           => 'MONKEY_ISLANDS',
}
