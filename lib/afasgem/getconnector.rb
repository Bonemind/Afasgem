# Implements communication with getconnectors
class Getconnector

	# Constructor, takes the name of the connector
	def initialize(name)
		@connectorname = name

		if Afasgem::debug
			# Build a debug client if the debug flag is set
			@client = Savon.client(
				wsdl: Afasgem::getconnector_url,
				log: true,
				log_level: :debug,
				pretty_print_xml: true
			)
		else
			# Build a normal client otherwise
			@client = Savon.client(wsdl: Afasgem::getconnector_url)
		end
	end

	# Set the number of results we want to have
	# Provides a fluent interface
	def take(count)
		@resultcount = count
		return self
	end

	# execute the request
	# Provides a fluent interface
	def execute
		resultscount = @resultcount || Afasgem.default_results
		resp = @client.call(:get_data, message: {token: Afasgem.get_token, connectorId: @connectorname, take: resultscount})
		xml_string = resp.hash[:envelope][:body][:get_data_response][:get_data_result]
		@raw_xml = xml_string
		@result = from_xml(xml_string)
		return self
	end

	# Returns the result as a hash
	# This includes the type definition
	def get_result
		execute unless @result
		return @result
	end

	# Returns the actual data as a hash
	def get_data
		execute unless @result
		return @result[:AfasGetConnector][@connectorname.to_sym]
	end

	# Returns the raw xml
	def get_raw_xml
		execute unless @raw_xml
		return @raw_xml
	end

	private

	# Source of code below: https://gist.github.com/huy/819999
	def from_xml(xml_io)
		begin
			result = Nokogiri::XML(xml_io)
			return { result.root.name.to_sym => xml_node_to_hash(result.root)}
		rescue Exception => e
			# raise your custom exception here
		end
	end

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
end
