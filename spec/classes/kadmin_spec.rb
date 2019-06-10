require 'spec_helper'

describe 'kerberos::kadmin::config', type: 'class' do
  on_supported_os($test_os).each do |os, facts|
    path = $test_config_dir[facts[:osfamily]]
    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_file("#{path}/kdc.conf") }
      it { should contain_file("#{path}/kadm5.acl") }
    end
  end
end

describe 'kerberos::kadmin', type: 'class' do
  on_supported_os($test_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
      it { should contain_class('kerberos::kadmin') }
      it { should contain_class('kerberos::kadmin::install') }
      it { should contain_class('kerberos::kadmin::config') }
      it { should contain_class('kerberos::kadmin::service') }
    end
  end
end
