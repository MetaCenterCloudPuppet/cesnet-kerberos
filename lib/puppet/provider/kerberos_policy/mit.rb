Puppet::Type.type(:kerberos_policy).provide(:mit) do
  commands kadmin: 'kadmin.local'

  mk_resource_methods

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
    kadmin(['add_policy'] + kadmin_args(@resource) + [@resource.value(:name)])
  end

  def exists?
    begin
      output = kadmin('get_policy', @resource.value(:name))
    rescue
      return false
    end
    output.split(/\n/).map(&:strip).any? do |line|
      line.match(/Policy: #{@resource.value(:name)}$/)
    end
  end

  def destroy
    kadmin('delete_policy', @resource.value(:name))
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

  def self.query_policy(name)
    output = kadmin('get_policy', name)

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
        resource.provider = new(query_policy(name))
      rescue
        nil
      end
    end
  end

  KERBEROS_POLICY_PROPERTIES.each_key do |property|
    define_method "#{property}=" do |new_value|
      kadmin([
        'modify_policy',
        "-#{property}",
        new_value,
        @resource.value(:name)
      ])
    end
  end
end
