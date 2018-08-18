require 'spec_helper'

describe 'trust_bundle fact' do
  before :each do
    if Facter.collection.respond_to?(:load)
      Facter.collection.load(:trust_bundle)
    else
      Facter.collection.loader.load(:trust_bundle)
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      path = case facts[:os]['family']
             when 'RedHat'
               if facts[:os]['release']['major'].to_i >= 7
                 '/etc/pki/tls/certs/ca-bundle.crt'
               else
                 '/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem'
               end
             when 'Debian'
               '/etc/ssl/certs/ca-certificates.crt'
             end

      before :each do
        allow(Facter.fact(:os)).to receive(:value).and_return(facts[:os])
      end

      after :each do
        Facter.clear
        Facter.clear_messages
      end

      it "is expected to be #{path}" do
        expect(Facter.fact(:trust_bundle).value).to eq(path)
      end
    end
  end
end
