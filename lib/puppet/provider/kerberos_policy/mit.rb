Puppet::Type.type(:kerberos_policy).provide(:mit) do
  optional_commands kadmin_local: 'kadmin.local'
  optional_commands kadmin_remote: 'kadmin'

  mk_resource_methods

  create_class_and_instance_method('local?') do |resource|
    if resource.value(:local).nil?
      !resource.value(:admin_keytab) && !resource.value(:admin_password)
    else
      resource.value(:local)
    end
  end

  # For instance method set *resource* to @resource.
  #
  # For class method set *resource* to the initial instance with required
  # parameters and properties set (from self.prefetch).
  create_class_and_instance_method('kadmin_cmd') do |resource, *args|
    admin_args = []
    resource.value(:admin_principal) &&
      admin_args << '-p' << resource.value(:admin_principal)
    if local?(resource)
      kadmin_local(admin_args + args)
    else
      resource.value(:admin_password) &&
        admin_args << '-w' << resource.value(:admin_password)
      unless resource.value(:admin_keytab).nil?
        admin_args << '-k'
        resource.value(:admin_keytab).empty? ||
          admin_args << '-t' << resource.value(:admin_keytab)
      end
      kadmin_remote(admin_args + args)
    end
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

  def self.policy_parse_line(line, entry)
    desc, value = line.split(/:\s*/, 2)
    (key = KERBEROS_POLICY_PROPERTIES.key(desc)).nil? && return
    if KERBEROS_POLICY_TIME_PROPERTIES.include?(key)
      entry[key.to_sym] = kerberos_munge_time(value)
    else
      entry[key.to_sym] = value ? value.to_i : 0
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
