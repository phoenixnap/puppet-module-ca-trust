require 'spec_helper'

if Puppet::Util::Package.versioncmp(Puppet.version, '4.5.0') >= 0
  describe 'Ca_trust::Resource::Anchor' do
    let(:contents) do
      File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'files', 'selfCA.pem')))
    end

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
          'content' => '',
        },
        {
          'ensure'  => 'present',
          'content' => '',
        },
        {
          'ensure'   => 'absent',
          'source'   => 'puppet:///modules/profile/my-internal-ca.pem',
          'filename' => 'org-ca',
        },
        {
          'ensure' => 'absent',
        },
        {
          'ensure' => 'absent',
          'filename' => 'org-ca',
        },
      ].each do |value|
        describe value.inspect do
          it {
            value['content'] = contents if value.key?('content')
            is_expected.to allow_value(value)
          }
        end
      end
    end

    context 'on invalid configurations' do
      [
        {
          'ensure' => 'foo',
          'source' => 'puppet:///modules/profile/my-internal-ca.pem',
        },
        {
          'contents' => '',
        },
        {
          'contents' => nil,
        },
        {
          'ensure'   => 'present',
          'source'   => 'puppet:///modules/profile/my-internal-ca.pem',
          'filename' => '/this/contains/a/path.crt',
        },
        {
          'ensure' => 'present',
          'source'   => 'puppet:///modules/profile/my-internal-ca.pem',
          'filename' => 'iendin.pem',
        },
        {
          'ensure' => 'present',
          'source'   => 'puppet:///modules/profile/my-internal-ca.pem',
          'filename' => 'iendin.crt',
        },
      ].each do |value|
        describe value.inspect do
          it { is_expected.not_to allow_value(value) }
        end
      end
    end
  end
end
