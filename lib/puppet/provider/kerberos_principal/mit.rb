Puppet::Type.type(:kerberos_principal).provide(:mit) do
  commands kadmin: 'kadmin.local'

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

  def create
    args = ['add_principal']
    @resource.value(:attributes).each_pair do |attr, value|
      op = value ? '+' : '-'
      args << "#{op}#{attr}"
    end
    if @resource.value(:password)
      args << '-pw'
      args << '"' + @resource.value(:password).gsub(/"/, "\\\"") + '"'
    else
      args << '-randkey'
    end
    @resource.value(:policy) &&
      args << ['-policy', @resource.value(:policy)]
    kadmin(args + [@resource.value(:name)])
  end

  def exists?
    begin
      output = kadmin('get_principal', @resource.value(:name))
    rescue
      return false
    end
    output.split(/\n/).map(&:strip).any? do |line|
      line.match(/Principal: #{@resource.value(:name)}(@.*)?/)
    end
  end

  def destroy
    kadmin('delete_principal', @resource.value(:name))
  end

  def self.parse_attributes(krbattrs, input_attributes = {})
    default = {}
    ATTRS_MAP.each_value do |v|
      default[v] = !(v =~ /^allow_.*$/).nil?
    end

    attributes = default
    krbattrs.split(/ +/).each do |krbattr|
      key = ATTRS_MAP[krbattr]
      # debug(" ==> attr: #{key}\n")
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

  def self.query_principal(name, input_attributes = {})
    output = kadmin('get_principal', name)

    entry = { name: name, policy: '' }
    output.split(/\n/).map(&:strip).each do |line|
      principal_parse_line(line, entry, input_attributes)
    end
    debug("relevant attributes of #{name}: #{entry[:attributes]}\n")
    entry
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      begin
        # debug("prefetching #{name}\n")
        resource.provider =
          new(query_principal(name, resource.value(:attributes)))
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
      kadmin(['modify_principal'] + args + [@resource.value(:name)])
  end

  def policy=(new_policy)
    if new_policy && !new_policy.empty?
      args = ['-policy', new_policy]
    else
      args = ['-clearpolicy']
    end
    kadmin(['modify_principal'] + args + [@resource.value(:name)])
  end
end
