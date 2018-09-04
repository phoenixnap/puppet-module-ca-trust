require 'spec_helper'

describe Facter::Util::Fact.to_s do
  let(:bundle) { StringIO.new(File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'files', 'bundle.pem')))) }

  before :each do
    Facter.clear
  end

  describe 'bundled_authorities' do
    before :each do
      allow(Facter.fact(:trust_bundle)).to receive(:value).and_return('/fakebundle.pem')
      allow(File).to receive(:open).with('/proc/self/status', 'rb').and_call_original
      allow(File).to receive(:open).with('/fakebundle.pem', 'r').and_return(bundle)
    end

    context 'with bundle data' do
      it 'returns a Hash of authority information' do
        expect(Facter.fact(:bundled_authorities)).not_to be_nil
        value = Facter.fact(:bundled_authorities).value
        expect(value).not_to be_nil
        expect(value).not_to be_empty
        expect(value).to be_a(Hash)
        k, v = value.first
        expect(k).to match(%r{\A[a-z0-9]+\z})
        expect(v).to be_a(Hash)
        expect(v).to have_key('issuer')
        expect(v).to have_key('subject')
        expect(v).to have_key('not_before')
        expect(v).to have_key('not_after')
        expect(Time.parse(v['not_after']).zone).to eq('UTC')
      end
    end
  end
end
