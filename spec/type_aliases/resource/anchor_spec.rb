require 'spec_helper'

if Puppet::Util::Package.versioncmp(Puppet.version, '4.5.0') >= 0
  describe 'Ca_trust::Resource::Anchor' do
    context 'on valid configurations' do
      [
        {
          'source' => 'puppet:///modules/profile/my-internal-ca.pem',
        },
        {
          'ensure' => 'present',
          'source' => 'puppet:///modules/profile/my-internal-ca.pem',
        },
        {
          'ensure'   => 'absent',
          'source'   => 'puppet:///modules/profile/my-internal-ca.pem',
          'filename' => 'org-ca',
        },
      ].each do |value|
        describe value.inspect do
          it { is_expected.to allow_value(value) }
        end
      end
    end

    context 'on invalid configurations' do
      [
        {
        },
        {
          'ensure' => 'present',
        },
        {
          'ensure' => 'foo',
          'source' => 'puppet:///modules/profile/my-internal-ca.pem',
        },
        {
          'ensure'   => 'present',
          'source'   => 'puppet:///modules/profile/my-internal-ca.pem',
          'filename' => '/this/contains/a/path.crt',
        },
      ].each do |value|
        describe value.inspect do
          it { is_expected.not_to allow_value(value) }
        end
      end
    end
  end
end
