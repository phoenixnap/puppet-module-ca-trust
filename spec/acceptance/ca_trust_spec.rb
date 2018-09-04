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

      describe 'ca_trust' do
        let(:manifest) { 'class { \'::ca_trust\': }' }

        it 'applies idempotently without errors' do
          apply_manifest_on(agent, manifest, catch_failures: true)
          expect(apply_manifest_on(agent, manifest, catch_failures: true).exit_code).to be_zero
        end

        describe package('ca-certificates') do
          it { is_expected.to be_installed }
        end
      end

      describe 'ca_trust::pem::anchor' do
        context 'installing a CA from source' do
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

        context 'install a CA from content' do
          let(:pp) do
            <<-EOT
            $cert_data = @(EOT)
            -----BEGIN CERTIFICATE-----
            MIIDnTCCAoWgAwIBAgIJALTCic2uAK0qMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNV
            BAYTAlVTMRAwDgYDVQQIDAdBcml6b25hMQ4wDAYDVQQHDAVUZW1wZTESMBAGA1UE
            CgwJUHVwcGV0RGV2MQ8wDQYDVQQLDAZTZWxmQ0ExDzANBgNVBAMMBlNlbGZDQTAe
            Fw0xODA4MDMwMDA0NTdaFw00NjA4MTYwMDA0NTdaMGUxCzAJBgNVBAYTAlVTMRAw
            DgYDVQQIDAdBcml6b25hMQ4wDAYDVQQHDAVUZW1wZTESMBAGA1UECgwJUHVwcGV0
            RGV2MQ8wDQYDVQQLDAZTZWxmQ0ExDzANBgNVBAMMBlNlbGZDQTCCASIwDQYJKoZI
            hvcNAQEBBQADggEPADCCAQoCggEBAMe2vYtllnzKqOXqZHzzDxX2Wv6yids4Jjh6
            x7O0JMUNKpzlzPAw+PoFXyP9B/Nw5AewzQKWtdv7q2LRzk1XxF6nBmkKN+Nee7ag
            f/X15Rd7BnOVefEZnzwbS2EhxxC20jchzUW5vvXxS+V4y3Bn7Fs1U9jEXkRPv88s
            iH0sCX+Aa4Ld2Jvktg98oblBTdaLQDG8LrcZ/9VO9M2HTvVhOimxrJ2ye1arJLTw
            9FAc0VL5nswIWwbfBmTBByyU6Y8a2A1AGQDNrQNap+PukaJYZO9ZnmKsutf8zR4u
            LZkY6wYO91rW9CcZWVgCU6rCsxLgcOVkWrmN2GiPztodyHI5GTMCAwEAAaNQME4w
            HQYDVR0OBBYEFFc/mAvE125aT6Lo4EWvIr7nP3IyMB8GA1UdIwQYMBaAFFc/mAvE
            125aT6Lo4EWvIr7nP3IyMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
            AIujrqFXGknolgR5psWRoFVtvg9kYqBwTm6mHYht4YiX4S5bMjI9xGCk40sbGoBO
            f+7gz38gNsvXJIjvHdORLjOrJ4B0ug+shayLZMN2z9pD2onumzk7S3PxWsuPDt5s
            /jwfJfO5Zo58G2RP8rAX2/6otNPxjCKitMuj1fBDV7K6UpmsCnPOP3VqMImerH82
            7CX8Ssfmy7VFM+4IV78oKjU8y5Z3PftO43X1VoV1rltXCKQKVUqJSu38h1KteaBb
            OD1z9jW06LI7vzqW1RwEAv1NToC8OqQuqJrgwyILrzKxZutiRmD5ObuTZm+6Ysff
            bUh7KOpx5DWzZl+wwubH01I=
            -----END CERTIFICATE-----
            | EOT
            ca_trust::pem::anchor { 'org-ca':
              content => $cert_data,
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
      end

      describe 'facts' do
        let(:custom_dir) { "#{agent[:distmoduledir]}/ca_trust/lib/facter/" }

        describe 'trust_bundle' do
          context 'when manifest' do
            let(:pp) do
              <<-EOT
              notify { "${::facts['trust_bundle']}": }
              EOT
            end

            it 'prints bundle location' do
              expect(apply_manifest_on(agent, pp, catch_failures: true).stdout).to contain(bundle)
            end
          end

          context 'when cli' do
            it 'prints bundle location' do
              expect(on(agent, "facter --custom-dir #{custom_dir} trust_bundle").stdout).to eq("#{bundle}\n")
            end
          end
        end

        describe 'bundled_authorities' do
          context 'when manifest' do
            let(:pp) do
              <<-EOT
              notify { "${::facts['bundled_authorities']}": }
              EOT
            end

            it 'returns the bundled authorities hash' do
              expect(apply_manifest_on(agent, pp, catch_failures: true).stdout).to match(%r{.*issuer.*})
            end
          end

          context 'it prints the bundled authorities hash' do
            it 'prints the bundled authorities hash' do
              expect(on(agent, "facter --custom-dir #{custom_dir} bundled_authorities").stdout).to match(%r{.*issuer.*})
            end
          end
        end
      end

      describe 'tasks/rebuild' do
        context 'when agent has bolt' do
          if agent[:platform] !~ %r{\A.*fedora.*\z}
            it 'rebuilds the bundle' do
              expect(on(agent, "rm #{bundle}").exit_code).to be_zero
              expect(on(agent, "bolt task run ca_trust::rebuild --nodes `hostname` --modulepath #{agent[:distmoduledir]} --transport local --verbose").exit_code).to be_zero
              expect(on(agent, "test -f #{bundle}").exit_code).to be_zero
            end
          else
            context 'bolt is unsupported' do
              it 'does nothing' do
                true
              end
            end
          end
        end
      end
    end
  end
end
