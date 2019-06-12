# Kerberos kadmin and kadmin.local provider commands
class Puppet::Provider::KerberosMit < Puppet::Provider
  initvars

  optional_commands kadmin_local: 'kadmin.local'
  optional_commands kadmin_remote: 'kadmin'

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
end
