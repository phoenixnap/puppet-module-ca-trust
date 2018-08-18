require 'beaker-puppet'
require 'beaker-pe'
require 'serverspec'
require 'spec_helper_acceptance.rb'

describe '::ca_trust' do
  agents.each do |agent|
    context "on #{agent[:platform]}" do
      let(:destination) do
        case agent[:platform]
        when %r{(^el|fedora).*$}
          '/usr/share/pki/ca-trust-source/anchors/org-ca.pem'
        when %r{(^deb|ubuntu).*$}
          '/usr/local/share/ca-certificates/org-ca.crt'
        else
          raise NotImplementedError, "Test is not implemented for #{agent[:platform]}."
        end
      end
      let(:bundle) do
        case agent[:platform]
        when %r{(^el-7|fedora).*$}
          '/etc/pki/tls/certs/ca-bundle.crt'
        when %r{^el-6.*$}
          # For some reason, on RHEL 6 /etc/pki/tls/certs/ca-bundle.crt is static and is not
          # a symlink to /etc/pki/ca_trust/extracted/pem/tls-ca-bundle.crt.
          # For now, I'm going to assume this is some kind of oversight, as I'm fairly certain
          # any apps would be pointing to the main bundle in certs, and not the bundle in extracted.
          # On RHEL 7, the tls/certs/ca-bundle is a symlink to extracted, as I think it should be.
          '/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem'
        when %r{(^deb|ubuntu).*$}
          '/etc/ssl/certs/ca-certificates.crt'
        else
          raise NotImplementedError, "Test is not implemented for #{agent[:platform]}."
        end
      end
      let(:tmp_p7) { '/tmp/cert.p7c' }
      let(:read_cmd) { 'openssl pkcs7 -noout -print_certs -in ' + tmp_p7 }
      let(:pkcs7_cmd) { 'openssl crl2pkcs7 -nocrl -certfile ' + bundle + ' > ' + tmp_p7 }

      context "on #{agent[:platform]}" do
        let(:manifest) { "class { '::ca_trust': }" }

        it 'applies idempotently without errors' do
          apply_manifest_on(agent, manifest, catch_failures: true)
          expect(apply_manifest_on(agent, manifest, catch_failures: true).exit_code).to be_zero
        end

        describe package('ca-certificates') do
          it { is_expected.to be_installed }
        end
      end

      describe 'ca_trust::pem::anchor' do
        context 'installing a CA' do
          let(:pp) do
            <<-EOT
            ca_trust::pem::anchor { 'org-ca':
              source => 'puppet:///modules/profile/selfCA.pem',
            }
            EOT
          end

          it 'applies idempotently without errors' do
            expect(apply_manifest_on(agent, pp, catch_failures: true).exit_code).to be 2
            expect(apply_manifest_on(agent, pp, catch_failures: true).exit_code).to be_zero
          end

          it 'installs the certificate file' do
            expect(on(agent, 'ls -l ' + destination).exit_code).to be_zero
          end

          it 'adds the certificate to the Root CA bundle' do
            expect(on(agent, pkcs7_cmd).exit_code).to be_zero
            expect(on(agent, read_cmd).stdout).to contain('CN=SelfCA')
          end
        end

        context 'removing a CA' do
          let(:pp) do
            <<-EOT
            ca_trust::pem::anchor { 'org-ca':
              ensure => 'absent',
            }
            EOT
          end

          it 'applies idempotently without errors' do
            expect(apply_manifest_on(agent, pp, catch_failures: true).exit_code).to be 2
            expect(apply_manifest_on(agent, pp, catch_failures: true).exit_code).to be_zero
          end

          it 'removes the certificate file' do
            expect(on(agent, 'ls -l ' + destination, acceptable_exit_codes: [1, 2]).exit_code).not_to be_zero
          end

          it 'removes the certificate from the Root CA bundle' do
            expect(on(agent, pkcs7_cmd).exit_code).to be_zero
            expect(on(agent, read_cmd).stdout).not_to contain('CN=SelfCA')
          end
        end
      end
    end
  end
end
