require 'spec_helper'

describe 'kerberos_policy', type: 'define' do
  on_supported_os($test_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          minlength:            6,
          history:              '1',
          maxlife:              '365 days 0:00:00',
          failurecountinterval: 0
        }
      end
      let(:title) { 'default-test' }

      it { should compile.with_all_deps }

      context 'with ensure => absent' do
        let(:params) do
          super().merge('ensure' => 'absent')
        end
        it { should compile }
      end
    end
  end
end
