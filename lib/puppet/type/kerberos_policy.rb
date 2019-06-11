KERBEROS_POLICY_PROPERTIES = {
  'maxlife'              => 'Maximum password life',
  'minlife'              => 'Minimum password life',
  'minlength'            => 'Minimum password length',
  'minclasses'           => 'Minimum number of password character classes',
  'history'              => 'Number of old keys kept',
  'maxfailure'           => 'Maximum password failures before lockout',
  'failurecountinterval' => 'Password failure count reset interval',
  'lockoutduration'      => 'Password lockout duration'
}

KERBEROS_POLICY_TIME_PROPERTIES = %w(
  maxlife
  minlife
  failurecountinterval
  lockoutduration
)

def kerberos_munge_time(value)
  return nil if value.nil?
  return value if value.is_a?(Integer)
  return 0 if value.empty?
  match = value.match(/((\d+)\s+day(s)?\s+)?(\d+)\s*:\s*(\d+)\s*:\s*(\d+)/)
  if match
    days = match[2] ? match[2].to_i : 0
    h = match[4].to_i
    m = match[5].to_i
    s = match[6].to_i
    # debug("kerberos_munge_time(#{value}): #{days} days #{h}:#{m}:#{s}")
    return ((24 * days + h) * 60 + m) * 60 + s
  end
  value
end

Puppet::Type.newtype(:kerberos_policy) do
  @doc = "Kerberos policy resource. It must be launched on admin server.

Example:

  kerberos_policy{'default':
    ensure     => 'present',
    minlength  => 6,
    history    => 3,
    maxlife    => '1 days 12:00:00',
  }
"

  ensurable

  autorequire(:class) { 'kerberos::client' }
  autorequire(:class) { 'kerberos::kadmin' }
  autorequire(:class) { 'kerberos::kdc' }
  autorequire(:exec) { 'kdb5_util-create' }

  newparam(:name, namevar: true) do
    desc 'Name of the Kerberos policy'
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

  KERBEROS_POLICY_PROPERTIES.each_pair do |name, desc|
    newproperty(name.to_sym) do
      type = KERBEROS_POLICY_TIME_PROPERTIES.include?(name) ? 'time' : 'number'
      desc "#{desc} (#{type})."

      if KERBEROS_POLICY_TIME_PROPERTIES.include?(name)
        munge { |value| kerberos_munge_time(value) }
      else
        validate do |value|
          !value.nil? && value.to_s =~ /^\d+$/ ||
            fail(ArgumentError, "#{name} must be a number")
        end
      end
    end
  end
end
