Facter.add('trust_bundle') do
  setcode do
    osfacts = Facter.value(:os)
    case osfacts['family']
    when 'RedHat'
      if osfacts['name'] == 'Fedora' || osfacts['release']['major'].to_i >= 7
        '/etc/pki/tls/certs/ca-bundle.crt'
      else
        # This CentOS 6 weirdness.
        '/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem'
      end
    when 'Debian'
      '/etc/ssl/certs/ca-certificates.crt'
    else
      raise NotImplementedError, "Operating system #{osfacts['family']} is unsupported by this module."
    end
  end
end
