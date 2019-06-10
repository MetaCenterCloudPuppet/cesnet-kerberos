require 'spec_helper'

describe 'kerberos::kprop::config', type: 'class' do
  on_supported_os($test_os).each do |os, facts|
    path = $test_config_dir[facts[:osfamily]]
    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_file("#{path}/kpropd.acl") }
    end
  end
end

describe 'kerberos::kprop', type: 'class' do
  on_supported_os($test_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
      it { should contain_class('kerberos::kprop') }
      it { should contain_class('kerberos::kprop::install') }
      it { should contain_class('kerberos::kprop::config') }
      it { should contain_class('kerberos::kprop::service') }
    end
  end
end
