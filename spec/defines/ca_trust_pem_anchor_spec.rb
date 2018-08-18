require 'spec_helper'

describe 'ca_trust::pem::anchor' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'my-ca' }
      let(:params) { { 'source' => 'puppet:///modules/profile/my-ca.pem' } }
      let(:installed_path) do
        case facts[:os]['family']
        when 'RedHat'
          '/usr/share/pki/ca-trust-source/anchors/my-ca.pem'
        when 'Debian'
          '/usr/local/share/ca-certificates/my-ca.crt'
        end
      end

      describe 'with ca_trust defaults' do
        context 'when present' do
          it { is_expected.to compile }
          it {
            is_expected.to contain_file(installed_path)
              .with('ensure' => 'present', 'source' => 'puppet:///modules/profile/my-ca.pem')
              .that_notifies('Exec[Update CA Trust Bundles]')
          }

          context 'when source undefined' do
            let(:params) { {} }

            it { is_expected.to raise_error(Puppet::Error, %r{.*Source is required.*}) }
          end
        end

        context 'when absent' do
          let(:params) { { 'source' => 'puppet:///modules/profile/my-ca.pem', 'ensure' => 'absent' } }

          it { is_expected.to compile }
          it { is_expected.to contain_exec('Update CA Trust Bundles') }
          it { is_expected.to contain_exec('Reset CA Trust Bundles').that_notifies('Exec[Update CA Trust Bundles]') }
          it {
            is_expected.to contain_file(installed_path)
              .with('ensure' => 'absent')
              .that_notifies('Exec[Reset CA Trust Bundles]')
          }

          context 'when source undefined' do
            let(:params) { { 'ensure' => 'absent' } }

            it { is_expected.to compile }
            it { is_expected.to contain_exec('Update CA Trust Bundles') }
            it { is_expected.to contain_exec('Reset CA Trust Bundles').that_notifies('Exec[Update CA Trust Bundles]') }
            it {
              is_expected.to contain_file(installed_path)
                .with('ensure' => 'absent')
                .that_notifies('Exec[Reset CA Trust Bundles]')
            }
          end
        end
      end
    end
  end
end
