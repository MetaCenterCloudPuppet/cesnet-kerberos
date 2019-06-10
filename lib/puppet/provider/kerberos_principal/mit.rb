Puppet::Type.type(:kerberos_principal).provide(:mit) do
  optional_commands kadmin_local: 'kadmin.local'
  optional_commands kadmin_remote: 'kadmin'

  mk_resource_methods

  ATTRS_MAP = {
    'DISALLOW_POSTDATED' => 'allow_postdated',
    'DISALLOW_FORWARDABLE' => 'allow_forwardable',
    'DISALLOW_TGT_BASED' => 'allow_tgs_req',
    'DISALLOW_RENEWABLE' => 'allow_renewable',
    'DISALLOW_PROXIABLE' => 'allow_proxiable',
    'DISALLOW_DUP_SKEY' => 'allow_dup_skey',
    'DISALLOW_ALL_TIX' => 'allow_tix',
    'DISALLOW_SVR' => 'allow_svr',
    'REQUIRES_PRE_AUTH' => 'requires_preauth',
    'REQUIRES_HW_AUTH' => 'requires_hwauth',
    'REQUIRES_PWCHANGE' => 'needchange',
    'PWCHANGE_SERVICE' => 'password_changing_service',
    'OK_AS_DELEGATE' => 'ok_as_delegate',
    'OK_TO_AUTH_AS_DELEGATE' => 'ok_to_auth_as_delegate',
    'NO_AUTH_DATA_REQUIRED' => 'no_auth_data_required',
    'LOCKDOWN_KEYS' => 'lockdown_keys'
  }

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

  def create
    args = ['add_principal']
    @resource.value(:attributes).each_pair do |attr, value|
      op = value ? '+' : '-'
      args << "#{op}#{attr}"
    end
    if @resource.value(:password)
      args << '-pw'
      args << @resource.value(:password)
    else
      args << '-randkey'
    end
    @resource.value(:policy) &&
      args << ['-policy', @resource.value(:policy)]
    kadmin_cmd(@resource, args + [@resource.value(:name)])
  end

  def exists?
    begin
      output = kadmin_cmd(@resource, 'get_principal', @resource.value(:name))
    rescue
      return false
    end
    output.split(/\n/).map(&:strip).any? do |line|
      line.match(/Principal: #{@resource.value(:name)}(@.*)?/)
    end
  end

  def destroy
    kadmin_cmd(@resource, 'delete_principal', @resource.value(:name))
  end

  def self.parse_attributes(krbattrs, input_attributes = {})
    default = {}
    ATTRS_MAP.each_value do |v|
      default[v] = !(v =~ /^allow_.*$/).nil?
    end

    attributes = default
    krbattrs.split(/ +/).each do |krbattr|
      key = ATTRS_MAP[krbattr]
      # debug(" ==> attr: #{key}")
      attributes[key] = (key =~ /^allow_.*$/).nil?
    end
    attributes.select { |k, _v| input_attributes.key?(k) }
  end

  def self.principal_parse_line(line, entry, input_attributes)
    m = line.match(/^Policy: *(.*)$/)
    m && m[1] != '[none]' &&
      entry[:policy] = m[1]

    m = line.match(/^Attributes: *(.*)$/)
    m && m[1] &&
      entry[:attributes] = parse_attributes(m[1], input_attributes)
  end

  def self.query_principal(name, resource)
    output = kadmin_cmd(resource, 'get_principal', name)

    entry = { name: name, policy: '' }
    output.split(/\n/).map(&:strip).each do |line|
      principal_parse_line(line, entry, resource.value(:attributes))
    end
    debug("relevant attributes of #{name}: #{entry[:attributes]}")
    entry
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      begin
        # debug("prefetching #{name}")
        resource.provider =
          new(query_principal(name, resource))
      rescue
        nil
      end
    end
  end

  def attributes=(new_attributes)
    args = []
    new_attributes.each_pair do |attr, value|
      op = value ? '+' : '-'
      args << "#{op}#{attr}"
    end
    args.empty? ||
      kadmin_cmd(@resource, ['modify_principal'] + args +
        [@resource.value(:name)])
  end

  def policy=(new_policy)
    if new_policy && !new_policy.empty?
      args = ['-policy', new_policy]
    else
      args = ['-clearpolicy']
    end
    kadmin_cmd(@resource, ['modify_principal'] + args +
      [@resource.value(:name)])
  end
end
