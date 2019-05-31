require 'spec_helper'

describe 'kerberos_principal', type: 'define' do
  on_supported_os($test_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          attributes: 'XXX'
        }
      end
      let(:title) { 'test-principal' }

      it { should compile.and_raise_error(/Attributes must be a hash/) }
    end
  end
end
