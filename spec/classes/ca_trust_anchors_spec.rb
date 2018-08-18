require 'spec_helper'

describe 'ca_trust::pem::anchors' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'when adding certificates' do
        let(:params) do
          {
            'resources' => {
              'org-ca' => {
                'source' => 'puppet:///modules/profile/org-ca.pem',
              },
              'my-ca' => {
                'source' => 'puppet:///modules/profile/my-ca.pem',
              },
              'self-signed' => {
                'source' => 'http://someplace.com/self-signed.txt',
              },
            },
          }
        end
        let(:installed_path) do
          case facts[:os]['family']
          when 'RedHat'
            '/usr/share/pki/ca-trust-source/anchors/self-signed.pem'
          when 'Debian'
            '/usr/local/share/ca-certificates/self-signed.crt'
          end
        end

        it { is_expected.to compile }
        it { is_expected.to contain_class('ca_trust') }
        it { is_expected.to have_ca_trust__pem__anchor_resource_count(3) }
        it {
          is_expected.to contain_file(installed_path)
            .that_notifies('Exec[Update CA Trust Bundles]')
        }
      end

      context 'when removing certificates' do
        let(:params) do
          {
            'resources' => {
              'org-ca' => {
                'source' => 'puppet:///modules/profiles/org-ca.pem',
                'ensure' => 'absent',
              },
            },
          }
        end
        let(:installed_path) do
          case facts[:os]['family']
          when 'RedHat'
            '/usr/share/pki/ca-trust-source/anchors/org-ca.pem'
          when 'Debian'
            '/usr/local/share/ca-certificates/org-ca.crt'
          end
        end

        it { is_expected.to compile }
        it { is_expected.to contain_class('ca_trust') }
        it { is_expected.to contain_exec('Update CA Trust Bundles') }
        it { is_expected.to contain_exec('Reset CA Trust Bundles').that_notifies('Exec[Update CA Trust Bundles]') }
        it {
          is_expected.to contain_file(installed_path)
            .with(ensure: 'absent')
            .that_notifies('Exec[Reset CA Trust Bundles]')
        }
      end
    end
  end
end
