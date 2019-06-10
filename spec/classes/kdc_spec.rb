require 'spec_helper'

describe 'kerberos::kdc::config', type: 'class' do
  on_supported_os($test_os).each do |os, facts|
    path = $test_config_dir[facts[:osfamily]]
    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_file("#{path}/kdc.conf") }
    end
  end
end

describe 'kerberos::kdc', type: 'class' do
  on_supported_os($test_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
      it { should contain_class('kerberos::kdc') }
      it { should contain_class('kerberos::kdc::install') }
      it { should contain_class('kerberos::kdc::config') }
      it { should contain_class('kerberos::kdc::service') }
    end
  end
end
