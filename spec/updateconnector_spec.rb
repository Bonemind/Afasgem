require 'spec_helper'
require './spec/afas_env.rb'
require 'afasgem/operators'
require 'afasgem'

describe UpdateConnector do
	include_context 'AFASEnv'

	# Hash used to test the CRUD of an item
	let(:articlehash) {
		return {
			ItCd: 1234,
			Ds: 'Test2',
			Grp: 666,
			BiSt: false,
			BiDc: 2,
			BiUn: 'UUR',
			PrFc: 1,
			CoLa: 'NL',
			VaRc: 5,
			EUSe: true,
			ChSa: true,
			ChPu: true
		}
	}

	it 'should handle nested objects' do
		connector = Afasgem.updateconnector_factory('FbItemArticle')

		# Hash to test the nesting functionality agains
		hash = {A: 'a', B: 'b',
					Objects: {
						nested1: { C: 'c', D: 'd' },
						nested2: { E: 'e', F: 'f' }
					}
				}

		# Expected output
		output = <<END
<?xml version="1.0"?>
<FbItemArticle xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <Element>
    <Fields Action="insert">
      <A>a</A>
      <B>b</B>
      <Objects>
        <nested1>
          <Element>
            <Fields Action="insert">
              <C>c</C>
              <D>d</D>
            </Fields>
          </Element>
        </nested1>
        <nested2>
          <Element>
            <Fields Action="insert">
              <E>e</E>
              <F>f</F>
            </Fields>
          </Element>
        </nested2>
      </Objects>
    </Fields>
  </Element>
</FbItemArticle>
END
		expect(connector.send(:build_xml, hash, 'insert')).to eq(output)

	end

	it 'should successfully create an article' do
		connector = Afasgem.updateconnector_factory('FbItemArticle')
		puts connector.insert(articlehash)
	end

	it 'should successfully update an article' do
		connector = Afasgem.updateconnector_factory('FbItemArticle')
		puts connector.update(articlehash)
	end

	it 'should successfully delete an article' do
		connector = Afasgem.updateconnector_factory('FbItemArticle')
		puts connector.delete(articlehash)
	end
end
