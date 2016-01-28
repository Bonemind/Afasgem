RSpec.shared_context 'AFASEnv' do
	before(:each) do
		Afasgem.configuration do |config|
			config.getconnector_url = 'getconnectorurl'
			config.updateconnector_url = 'updateconnectorurl'
			config.dataconnector_url = 'dataconnectorurl'
			config.token = 'token'
			config.default_results = 150
			config.debug = true
		end
	end
end
