require 'spec_helper'

describe 'kerberos_principal', type: 'define' do
  on_supported_os($test_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          attributes: {
            'requires_preauth' => true
          },
          policy: 'default-test'
        }
      end
      let(:title) { 'test-principal' }

      it { should compile.with_all_deps }

      context 'with ensure => absent' do
        let(:params) do
          super().merge('ensure' => 'absent')
        end
        it { should compile }
      end

      context 'with admin_password' do
        let(:params) do
          super().merge('admin_password' => 'changeit')
        end
        it { should compile }
      end

      context 'with admin_keytab' do
        let(:params) do
          super().merge('admin_keytab' => '/etc/krb5.keytab')
        end
        it { should compile }
      end
    end
  end
end
