require 'openssl'

Facter.add('bundled_authorities') do
  setcode do
    bundle = Facter.value(:trust_bundle)

    if bundle.nil? || bundle.empty?
      raise(Puppet::Error, 'Could not resolve trust_bundle location.')
    end

    begin
      buffer = ''
      pem = []
      File.open(bundle, 'r').each do |line|
        line.force_encoding('UTF-8')
        if line =~ %r{^(.*)\s*#.*$}
          line = Regexp.last_match[1]
        end
        next if line.empty? || line == %r{^\s*$}
        buffer += line
        next unless line =~ %r{^\s*-{5}\s?END CERTIFICATE\s?-{5}\s*$}
        begin
          pem << OpenSSL::X509::Certificate.new(buffer)
        rescue
          Puppet.error("Failure to parse certificate authority: #{e.message}")
          next
        ensure
          buffer = ''
        end
      end

      pem.reduce({}) do |memo, cert|
        memo.merge(
          OpenSSL::Digest::SHA1.new(cert.to_der).to_s => {
            'subject'     => cert.subject.to_s,
            'issuer'      => cert.issuer.to_s,
            'not_before'  => cert.not_before.utc.to_s,
            'not_after'   => cert.not_after.utc.to_s,
          },
        )
      end
    rescue StandardError => e
      Puppet.error("Failed to read CA Trust Bundle: #{e.message}")
      return []
    end
  end
end
