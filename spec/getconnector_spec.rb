require 'spec_helper'
require './spec/afas_env.rb'
require 'pp'
require 'afasgem/operators'

describe GetConnector do
	include_context 'AFASEnv'

	it 'should provide a fluent interface for pagination functionality' do
		connector = Afasgem.getconnector_factory('Profit_Debtor')
		expect(connector).to be_a(GetConnector)
		connector = connector.take(10)
		expect(connector).to be_a(GetConnector)
		connector = connector.skip(10)
		expect(connector).to be_a(GetConnector)
		connector = connector.next
		expect(connector).to be_a(GetConnector)
		connector = connector.previous
		expect(connector).to be_a(GetConnector)
		connector = connector.page(5)
		expect(connector).to be_a(GetConnector)
	end

	it 'should throw an argumenterror when setting less than 1 record per page' do
		connector = Afasgem.getconnector_factory('Profit_Debtor')
		expect{ connector.take(0) }.to raise_error(ArgumentError)
		expect{ connector.take(-1) }.to raise_error(ArgumentError)
	end

	it 'should throw an argumenterror when skipping less than 0 record per page' do
		connector = Afasgem.getconnector_factory('Profit_Debtor')
		expect{ connector.take(-1) }.to raise_error(ArgumentError)
	end

	it 'should throw an argumenterror when setting a pagenumber less than 1' do
		connector = Afasgem.getconnector_factory('Profit_Debtor')
		expect{ connector.take(0) }.to raise_error(ArgumentError)
		expect{ connector.take(-1) }.to raise_error(ArgumentError)
	end
end
