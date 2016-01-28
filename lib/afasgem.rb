require "afasgem/version"
require 'afasgem/configuration'

module Afasgem
	extend Configuration

	define_setting :getconnector_url
	define_setting :updateconnector_url
	define_setting :dataconnector_url
end
