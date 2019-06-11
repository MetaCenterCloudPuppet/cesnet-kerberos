require 'puppet/parameter/boolean'

Puppet::Type.newtype(:kerberos_principal) do
  @doc = "Create a new Kerberos principal. It must be launched on admin server.

Example:

  kerberos_principal{'hawking@EXAMPLE.COM':
    ensure     => 'present',
    attributes => {
      'allow_tix'        => true,
      'requires_preauth' => true,
    },
    policy     => 'default',
  }
"

  ensurable

  autorequire(:class) { 'kerberos::client' }
  autorequire(:class) { 'kerberos::kadmin' }
  autorequire(:class) { 'kerberos::kdc' }
  autorequire(:exec) { 'kdb5_util-create' }
  autorequire(:kerberos_policy) { self[:policy] }

  newparam(:name, namevar: true) do
    desc 'Name of the Kerberos principal'
  end

  newparam(:password) do
    desc 'Principal password. If not specified, random key will be used.'
  end

  newparam(:admin_principal) do
    desc 'Admin principal for kadmin or kadmin.local client.'
  end

  newparam(:admin_password) do
    desc 'Admin password for remote kadmin client.'
  end

  newparam(:admin_keytab) do
    desc 'Admin keytab for remote kadmin client.'
  end

  newparam(:local, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc 'Prefer kadmin.local (default is according to admin_password or \
admin_keytab parameters).'
  end

  newproperty(:attributes) do
    desc 'Principal attributes.'

    validate do |value|
      value.is_a?(Hash) || \
        fail(ArgumentError, 'Attributes must be a hash')
    end
  end

  newproperty(:policy) do
    desc 'Kerberos policy.'
  end
end
