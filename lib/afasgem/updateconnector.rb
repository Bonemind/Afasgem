class UpdateConnector
	def initialize(name)
		@connectorname = name
		if Afasgem::debug
			# Build a debug client if the debug flag is set
			@client = Savon.client(
				wsdl: Afasgem::updateconnector_url,
				log: true,
				log_level: :debug,
				pretty_print_xml: true
			)
		else
			# Build a normal client otherwise
			@client = Savon.client(wsdl: Afasgem::updateconnector_url)
		end
	end

	def client
		return @client
	end

	private

	def execute
		message = {
			token: Afasgem.get_token,
			connectorId: @connectorname,
		}
		resp = @client.call(:get_data, message: message)
	end

end
