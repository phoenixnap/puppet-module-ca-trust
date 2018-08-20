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
      let(:contents) do
        File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', 'files', 'selfCA.pem')))
      end

      describe 'with ca_trust defaults' do
        context 'when present' do
          context 'with source defined' do
            it { is_expected.to compile }
            it {
              is_expected.to contain_file(installed_path)
                .with('ensure' => 'present', 'source' => 'puppet:///modules/profile/my-ca.pem')
                .that_notifies('Exec[Update CA Trust Bundles]')
            }
          end

          context 'with content defined' do
            let(:params) { { 'content' => contents } }

            it { is_expected.to compile }
            it {
              is_expected.to contain_file(installed_path)
                .with('ensure' => 'present', 'content' => contents)
                .that_notifies('Exec[Update CA Trust Bundles]')
            }
          end

          context 'with content and source defined' do
            let(:params) do
              {
                'content' => contents,
                'source'  => 'puppet:///modules/profile/my-ca.pem',
              }
            end

            it { is_expected.to compile }
            it {
              is_expected.to contain_file(installed_path)
                .with('ensure' => 'present', 'content' => contents, 'source' => nil)
                .that_notifies('Exec[Update CA Trust Bundles]')
            }
          end

          context 'when source and contents undefined' do
            let(:params) { {} }

            it { is_expected.to raise_error(Puppet::Error, %r{.*Source or content is required.*}) }
          end

          context 'when filename ends in extension' do
            let(:title) do
              case facts[:os]['family']
              when 'RedHat'
                'my-ca.pem'
              when 'Debian'
                'my-ca.crt'
              end
            end

            it { is_expected.to raise_error(Puppet::Error) }
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

          context 'when source and content undefined' do
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
