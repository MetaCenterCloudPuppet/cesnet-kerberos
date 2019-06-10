require 'spec_helper'

describe 'kerberos::client::config', type: 'class' do
  on_supported_os($test_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_file('/etc/krb5.conf') }
    end
  end
end

describe 'kerberos::client', type: 'class' do
  on_supported_os($test_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
      it { should contain_class('kerberos::client') }
      it { should contain_class('kerberos::client::install') }
      it { should contain_class('kerberos::client::config') }
      it { should contain_class('kerberos::client::service') }
    end
  end
end
