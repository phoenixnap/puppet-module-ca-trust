require 'spec_helper'

describe 'ca_trust' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:exec_path) { ['/bin', '/usr/bin', '/sbin', '/usr/bin', '/usr/local/bin'] }

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('ca_trust::install') }
        it { is_expected.to contain_package('ca-certificates').with('ensure' => 'present') }
        case facts[:os]['family']
        when 'RedHat'
          case facts[:os]['release']['major']
          when '7'
            it {
              is_expected.to contain_exec('Update CA Trust Bundles')
                .with('command' => 'update-ca-trust', 'path' => exec_path, 'refreshonly' => true)
            }
          when '6'
            it {
              is_expected.to contain_exec('Update CA Trust Bundles')
                .with('command' => 'update-ca-trust extract', 'path' => exec_path, 'refreshonly' => true)
            }
          end
        when 'Ubuntu'
          it {
            is_expected.to contain_exec('Update CA Trust Bundles')
              .with('command' => 'update-ca-certificates', 'path' => exec_path, 'refreshonly' => true)
          }
        end
      end

      context 'without package management' do
        let(:params) { { 'manage_pkg' => false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_package('ca-certificates') }
      end

      context 'with dir, update_cmd and package specified' do
        let(:params) do
          {
            'trust_dir'       => '/other',
            'anchor_dir'      => '/other/anchors',
            'update_cmd'      => '/usr/bin/foo',
            'package_name'    => 'nothing',
            'package_version' => '4.1.0',
            'anchors'         => {
              'org-ca' => {
                'source' => 'puppet:///modules/profile/my-ca.pem',
              },
            },
          }
        end
        let(:installed_path) do
          case facts[:os]['family']
          when 'RedHat'
            '/other/anchors/org-ca.pem'
          when 'Debian'
            '/other/anchors/org-ca.crt'
          end
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_exec('Update CA Trust Bundles')
            .with('command' => '/usr/bin/foo', 'path' => exec_path, 'refreshonly' => true)
        }
        it { is_expected.to contain_package('nothing').with('ensure' => '4.1.0') }
        it { is_expected.to contain_file(installed_path).that_notifies('Exec[Update CA Trust Bundles]') }
      end

      context 'with anchors specified' do
        let(:params) do
          {
            'anchors' => {
              'org-ca' => {
                'source' => 'puppet:///modules/profile/my-ca.pem',
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

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('Update CA Trust Bundles') }
        it {
          is_expected.to contain_ca_trust__pem__anchor('org-ca')
            .with('ensure' => 'present', 'source' => 'puppet:///modules/profile/my-ca.pem', 'filename' => 'org-ca')
        }
        it {
          is_expected.to contain_file(installed_path)
            .with('ensure' => 'present', 'source' => 'puppet:///modules/profile/my-ca.pem')
            .that_notifies('Exec[Update CA Trust Bundles]')
        }
        it { is_expected.to have_ca_trust__pem__anchor_resource_count(1) }
      end
    end
  end
end
