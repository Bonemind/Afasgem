require 'savon'
require 'pp'
require 'optparse'

# Parse xml to a hash
def from_xml(xml_io)
	begin
		result = Nokogiri::XML(xml_io)
		return { result.root.name.to_sym => xml_node_to_hash(result.root)}
	rescue Exception => e
		puts e.backtrace
		raise
	end
end

# Parse each node to a hash
def xml_node_to_hash(node)
	# If we are at the root of the document, start the hash
	if node.element?
		result_hash = {}
		if node.attributes != {}
			attributes = {}
			node.attributes.keys.each do |key|
				attributes[node.attributes[key].name.to_sym] = node.attributes[key].value
			end
		end
		if node.children.size > 0
			node.children.each do |child|
				result = xml_node_to_hash(child)

				if child.name == "text"
					unless child.next_sibling || child.previous_sibling
						return result unless attributes
						result_hash[child.name.to_sym] = result
					end
				elsif result_hash[child.name.to_sym]

					if result_hash[child.name.to_sym].is_a?(Object::Array)
						result_hash[child.name.to_sym] << result
					else
						result_hash[child.name.to_sym] = [result_hash[child.name.to_sym]] << result
					end
				else
					result_hash[child.name.to_sym] = result
				end
			end
			if attributes
				#add code to remove non-data attributes e.g. xml schema, namespace here
				#if there is a collision then node content supersets attributes
				result_hash = attributes.merge(result_hash)
			end
			return result_hash
		else
			return attributes
		end
	else
		return node.content.to_s
	end
end


# The dataconnector url, will probably not need to change
dataconnector_url = 'https://profitweb.afasonline.nl/profitservices/DataConnector.asmx?WSDL'

# The username to use
username = nil

# The password to use
password = nil

# The connector we want a description of
connector_name = nil

# The AFAS environment, probably in the format: 'X12345XX'
environment_id = nil

# Create an optionparser
OptionParser.new do |opts|
	# Set username
	opts.on('-u', '--username NAME', 'AFAS username') { |v| username = v }

	# Set password
	opts.on('-p', '--password PASSWORD', 'AFAS password') { |v| password = v }

	# Set connector name
	opts.on('-c', '--connector CONNECTOR', 'Name of the UpdateConnector') { |v| connector_name = v }

	# Set environment
	opts.on('-e', '--environment ENVIRONMENT', 'Name of the environment') { |v| environment_id = v }

	# Display help
	opts.on_tail("-h", "--help", "Show this message") do
		puts opts
		exit
	end
	# Parse
end.parse!

# All params are required, fail is one is missing
fail ArgumentError.new('Username is required') unless username
fail ArgumentError.new('Password is required') unless password
fail ArgumentError.new('Connector name is required') unless connector_name
fail ArgumentError.new('Environment name is required') unless environment_id

# Setup Savon with the credentials the user supplied
client = Savon.client(wsdl: dataconnector_url, basic_auth: [username, password])
resp = client.call(:execute, {
	message: {
		environmentId: environment_id,
		userId: username,
		password: password,
		dataID: 'GetXmlSchema',
		parametersXml: "<Parameters><UpdateConnectorId>#{connector_name}</UpdateConnectorId></Parameters>"
	}
})

# Get response xml out of wrapper
xml = resp.hash[:envelope][:body][:execute_response][:execute_result]


schemaxml = from_xml(xml)[:AfasDataConnector][:ConnectorData][:Schema]
a = Nokogiri::XML(schemaxml).remove_namespaces!

main_object_xpath = '//*[@name="Fields" and not(ancestor::*[@name="Objects"])]'
nested_objects_xpath = '//*[@name="Objects"]/complexType/sequence/*'
nested_objects_fields_xpath = '*//*[@name="Fields"]/complexType/sequence'


# Array of properties of the main object, contains comment and xml element alternating
main = a.xpath(main_object_xpath)[0].children.children.children
nested = a.xpath(nested_objects_xpath)

def print_fields(field_array)
	field_array.each do |el|
		if el.is_a?(Nokogiri::XML::Comment)
			puts '-' * 80
			puts el
		end
		if el.is_a?(Nokogiri::XML::Element)
			puts el.attributes['name'].value
			puts 'Optional' if el.attributes['nillable']
		end
	end
end

puts '*' * 8
puts connector_name
puts '*' * 80
print_fields(main)

nested.each do |el|
	puts '=' * 80
	puts el.attributes['name'].value
	puts '=' * 80
	fields = el.xpath(nested_objects_fields_xpath).children
	print_fields(fields)
end

