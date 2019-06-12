require File.expand_path(
  File.join(File.dirname(__FILE__), '..', 'kerberos_mit.rb'))
Puppet::Type.type(:kerberos_policy).provide(
  :mit,
  parent: Puppet::Provider::KerberosMit
) do
  mk_resource_methods

  if Puppet.version.nil?
    @convert = true
  else
    @convert = Gem::Version.new(Puppet.version) >= Gem::Version.new('4.0.0')
  end

  def kadmin_args(resource)
    args = []
    KERBEROS_POLICY_PROPERTIES.each_key do |k|
      (v = resource.value(k)).nil? &&
        next
      args << "-#{k}" << v
    end
    args
  end

  def create
    kadmin_cmd(@resource, ['add_policy'] + kadmin_args(@resource) +
      [@resource.value(:name)])
  end

  def exists?
    begin
      output = kadmin_cmd(@resource, 'get_policy', @resource.value(:name))
    rescue
      return false
    end
    output.split(/\n/).map(&:strip).any? do |line|
      line.match(/Policy: #{@resource.value(:name)}$/)
    end
  end

  def destroy
    kadmin_cmd(@resource, 'delete_policy', @resource.value(:name))
  end

  def self.munge_int(value)
    if @convert
      value ? value.to_i : 0
    else
      value
    end
  end

  def self.policy_parse_line(line, entry)
    desc, value = line.split(/:\s*/, 2)
    (key = KERBEROS_POLICY_PROPERTIES.key(desc)).nil? && return
    if KERBEROS_POLICY_TIME_PROPERTIES.include?(key)
      entry[key.to_sym] = kerberos_munge_time(value)
    else
      entry[key.to_sym] = munge_int(value)
    end
  end

  def self.query_policy(name, resource)
    output = kadmin_cmd(resource, 'get_policy', name)

    entry = {}
    output.split(/\n/).map(&:strip).each do |line|
      policy_parse_line(line, entry)
    end
    debug("the fetched policy #{name}: #{entry}")
    entry
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      begin
        # debug("prefetching #{name}\n")
        resource.provider = new(query_policy(name, resource))
      rescue
        nil
      end
    end
  end

  KERBEROS_POLICY_PROPERTIES.each_key do |property|
    define_method "#{property}=" do |new_value|
      kadmin_cmd(@resource, [
        'modify_policy',
        "-#{property}",
        new_value,
        @resource.value(:name)
      ])
    end
  end
end
