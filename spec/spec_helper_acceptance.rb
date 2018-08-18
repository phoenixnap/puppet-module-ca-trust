require 'serverspec'
require 'beaker-puppet'
require 'beaker-pe'
require 'beaker-rspec'

agent_version = ENV['BEAKER_agent_version'] || 'latest'
collection = ENV['BEAKER_collection'] || 'puppet5'
agent_yum_url = ENV['BEAKER_yum_url'] || 'http://yum.puppetlabs.com'
agent_apt_url = ENV['BEAKER_apt_url'] || 'http://apt.puppetlabs.com'
opts = {
  release_yum_repo_url: agent_yum_url,
  release_apt_repo_url: agent_apt_url,
}

install_puppetlabs_release_repo(agents, collection, opts)
agents.each do |agent|
  install_package(agent, 'puppet-agent', agent_version.eql?('latest') ? nil : agent_version)
  install_puppet_module_via_pmt_on(agent, module_name: 'puppetlabs-stdlib', version: '4.25.1')
  on(agent, "mkdir -p #{agent[:distmoduledir]}/profile/files")
  scp_to(agent, './spec/fixtures/files/selfCA.pem', "#{agent[:distmoduledir]}/profile/files/")
end
install_dev_puppet_module(source: './', module_name: 'ca_trust')

RSpec.configure do |c|
  c.formatter = :documentation
end
