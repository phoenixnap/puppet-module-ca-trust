#!/opt/puppetlabs/puppet/bin/ruby

require 'open3'
require 'puppet'
require 'json'

##
# This script does it's best to clear out and rebuild the system's
# Certificate Authority Bundle.
##

TASK_CA_TRUST_RESET_PATH = {
  'PATH' => ['/opt/puppetlabs/puppet/bin', '/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'].join(':'),
}.freeze

def env
  TASK_CA_TRUST_RESET_PATH
end

def os
  stdout, stderr, status = Open3.capture3(env, 'facter os.family')
  raise(Puppet::Error, "Error during OS discovery: #{stderr}") unless status.success?
  raise(Puppet::Error, 'Unknown OS') if stdout.empty?
  stdout.strip
end

def release
  stdout, stderr, status = Open3.capture3(env, 'facter os.release.major')
  raise(Puppet::Error, "Error during OS discovery: #{stderr}") unless status.success?
  raise(Puppet::Error, 'Cannot determin OS Major Release') if stdout.empty?
  stdout.strip
end

def run_platform
  local_os = os

  case local_os
  when 'RedHat'
    rebuild_redhat
  when 'Debian'
    rebuild_debian
  else
    raise(Puppet::Error, "Unsupported OS: #{local_os}")
  end
end

def rebuild_redhat
  _, stderr, status = Open3.capture3(env, 'yum check-update ca-certificates')
  raise(Puppet::Error, "Invocation of yum check-update ca-certificates failed: #{stderr}") unless [0, 100].include?(status.exitstatus)

  if status.exitstatus == 100
    _, stderr, status = Open3.capture3(env, 'yum update -y ca-certificates')
    raise(Puppet::Error, "Invocation of 'yum update -y ca-certificates' failed: #{stderr}") unless status.exitstatus.zero?
  else
    _, stderr, status = Open3.capture3(env, 'yum reinstall -y ca-certificates')
    raise(Puppet::Error, "Invocation of 'yum reinstall -y ca-certificates' failed: #{stderr}") unless status.exitstatus.zero?
  end

  option = (release.to_i >= 7) ? '' : ' extract'
  _, stderr, status = Open3.capture3(env, "update-ca-trust#{option}")
  raise(Puppet::Error, "Invocation of 'update-ca-trust#{option} failed: #{stderr}") unless status.exitstatus.zero?
end

def rebuild_debian
  _, stderr, status = Open3.capture3(env, 'update-ca-certificates --fresh')
  raise(Puppet::Error, "Invocation of 'update-ca-certificates --fresh' failed: #{stderr}") unless status.exitstatus.zero?
end

def exc_to_error(msg, e)
  {
    'status' => 'error',
    '_error' => {
      'msg'     => msg,
      'kind'    => e.class.name.gsub('::', '/'),
      'details' => e.message,
    },
  }
end

begin
  run_platform
rescue Puppet::Error => e
  STDERR.write(exc_to_error('Command failed.', e).to_json)
  exit(1)
rescue StandardError => e
  STDERR.write(exc_to_error('Unexpected error.', e).to_json)
  exit(1)
end

STDOUT.write({ 'status' => 'success' }.to_json)
exit(0)
