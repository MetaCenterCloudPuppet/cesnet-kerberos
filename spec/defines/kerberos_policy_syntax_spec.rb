require 'spec_helper'

describe 'kerberos_policy', type: 'define' do
  on_supported_os($test_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          minlength: 'XXX'
        }
      end
      let(:title) { 'default-test' }

      it { should compile.and_raise_error(/minlength must be a number/) }
    end
  end
end
