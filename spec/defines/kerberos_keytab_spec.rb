require 'spec_helper'

describe 'kerberos::keytab', type: 'define' do
  on_supported_os($test_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          principals: [
            'host/host1.example.com@EXAMPLE.COM',
            'host/host2.example.com@EXAMPLE.COM'
          ],
        }
      end
      let(:title) { '/etc/krb5.keytab' }

      it { should compile.with_all_deps }
    end
  end
end
