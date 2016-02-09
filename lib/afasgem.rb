require "afasgem/version"
require 'afasgem/configuration'
require 'afasgem/getconnector'
require 'afasgem/updateconnector'
require 'afasgem/operators'
require 'savon'
require 'nokogiri'

module Afasgem
	# Make the gem configurable
	# See afasgem/configuration.rb for code origin
	extend Configuration

	# The WSDL url of the getconnector
	define_setting :getconnector_url

	# The WSDL url of the updateconnector
	define_setting :updateconnector_url

	# The WSDL url of the dataconnector
	define_setting :dataconnector_url
	# The token, this is only the actual token, not the whole xml thing
	define_setting :token


	# The number of results to request by default
	define_setting :default_results, 100

	# Defines whether the requests and responses should be printed
	define_setting :debug, false

	# Constructs a getconnect for the passed connector name
	def self.getconnector_factory(name)
		return GetConnector.new(name)
	end

	# Constructs an updateconnector for the passed connector name
	def self.updateconnector_factory(name)
		return UpdateConnector.new(name)
	end

	# Builds the token xml from the configured token
	def self.get_token
		return "<token><version>1</version><data>#{Afasgem::token}</data></token>"
	end
end
