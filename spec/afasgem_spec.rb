require 'spec_helper'
require 'pp'

describe Afasgem do
	it 'can be configured' do
		expect(Afasgem::default_results).to eq(100)
		expect(Afasgem::debug).to eq(false)
		Afasgem.configuration do |config|
			config.getconnector_url = 'getconnectorurl'
			config.updateconnector_url = 'updateconnectorurl'
			config.dataconnector_url = 'dataconnectorurl'
			config.token = 'token'
			config.default_results = 150
			config.debug = true
		end
		expect(Afasgem::getconnector_url).to eq('getconnectorurl')
		expect(Afasgem::updateconnector_url).to eq('updateconnectorurl')
		expect(Afasgem::dataconnector_url).to eq('dataconnectorurl')
		expect(Afasgem::token).to eq('token')
		expect(Afasgem::default_results).to eq(150)
		expect(Afasgem::debug).to eq(true)
	end

	it 'should build a correct token' do
		Afasgem.configuration do |config|
			config.token = 'test'
		end
		expect(Afasgem.get_token).to eq('<token><version>1</version><data>test</data></token>')
	end

	it 'should build a getconnector' do
		connector = Afasgem.getconnector_factory('Profit_Debtor')
		expect(connector).to be_a(GetConnector)
		expect(connector.instance_variable_get(:@connectorname)).to eq('Profit_Debtor')
	end

	it 'should build an updateconnector' do
		connector = Afasgem.updateconnector_factory('FbItemArticle')
		expect(connector).to be_a(UpdateConnector)
		expect(connector.instance_variable_get(:@connectorname)).to eq('FbItemArticle')
	end
end
