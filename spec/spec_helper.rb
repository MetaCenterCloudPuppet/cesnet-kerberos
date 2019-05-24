require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

include RspecPuppetFacts

require 'simplecov'
require 'simplecov-console'

SimpleCov.start do
  add_filter '/spec'
  add_filter '/vendor'
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])
end

$test_os={
    :supported_os => [
        {
            'osfamily' => 'Debian',
            'operatingsystem' => 'Debian',
            'operatingsystemrelease' => ['9']
        }, {
            'osfamily' => 'RedHat',
            'operatingsystem' => 'Fedora',
            'operatingsystemrelease' => ['30']
        }, {
            'osfamily' => 'RedHat',
            'operatingsystem' => 'RedHat',
            'operatingsystemrelease' => ['7']
        }, {
            'osfamily' => 'RedHat',
            'operatingsystem' => 'CentOS',
            'operatingsystemrelease' => ['7']
        }, {
            'osfamily' => 'Debian',
            'operatingsystem' => 'Ubuntu',
            'operatingsystemrelease' => ['16.04']
        }
    ]
}

$test_config_dir={
  'Debian' => '/etc/krb5kdc',
  'RedHat' => '/var/kerberos/krb5kdc',
}
