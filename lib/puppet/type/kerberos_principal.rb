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

  newparam(:name, namevar: true) do
    desc 'Name of the Kerberos principal'
  end

  newparam(:password) do
    desc 'Principal password. If not specified, random key will be used.'
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

  autorequire(:exec) do
    'kdb5_util-create'
  end
end
