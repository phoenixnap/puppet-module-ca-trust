require 'spec_helper'

if Puppet::Util::Package.versioncmp(Puppet.version, '4.5.0') >= 0
  describe 'Ca_trust::Resource::Anchors' do
    context 'on valid configurations' do
      [
        {
          'org-ca.pem' => {
            'source' => 'puppet:///modules/profile/my-internal-ca.pem',
          },
          'another.pem' => {
            'ensure' => 'present',
            'source' => 'puppet:///modules/profile/my-internal-ca.pem',
          },
          'my-company-ca' => {
            'ensure'   => 'absent',
            'source'   => 'puppet:///modules/profile/my-internal-ca.pem',
            'filename' => 'org-ca',
          },
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
          'org-ca' => {},
        },
        {
          'company-ca.pem' => {
            'ensure' => 'present',
          },
        },
        {
          'foo' => {
            'ensure' => 'foo',
            'source' => 'puppet:///modules/profile/my-internal-ca.pem',
          },
        },
        {
          'org-ca' => {
            'source' => 'puppet:///modules/profile/my-internal-ca.pem',
          },
          'another' => {
            'ensure' => 'foobar',
          },
          '/this/has/path/my-ca' => {
            'source' => 'puppet:///modules/profile/my-ca.pem',
          },
        },
      ].each do |value|
        describe value.inspect do
          it { is_expected.not_to allow_value(value) }
        end
      end
    end
  end
end
