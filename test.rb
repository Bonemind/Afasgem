require 'savon'
require 'pp'

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


client = Savon.client(wsdl: 'https://profitweb.afasonline.nl/profitservices/DataConnector.asmx?WSDL', basic_auth: ['49329.AgroPro', 'Connector1'])
x = client.call(:execute, { message: { environmentId: 'O49329AB', userId: '49329.AgroPro', password: 'Connector1', dataID: 'GetXmlSchema', parametersXml: '<Parameters><UpdateConnectorId>PtProject</UpdateConnectorId></Parameters>'} })
xml = x.hash[:envelope][:body][:execute_response][:execute_result]
# puts from_xml(xml)[:AfasDataConnector][:ConnectorData][:Schema]
# puts from_xml(xml)[:AfasDataConnector][:ConnectorData][:Id]
y = from_xml(xml)[:AfasDataConnector][:ConnectorData][:Schema]

arr = from_xml(y)[:schema][:element][:complexType][:sequence][:element][:complexType][:sequence][:element]
arr.each do |t|
	comments = t[:complexType][:sequence][:comment]

	fields = t[:complexType][:sequence][:element]

	transformed_fields = fields.map do |el|
		simpleType = el[:simpleType]
		type = nil
		type = simpleType[:restriction][:base] if simpleType
		[el[:name], el[:nillable], type ]
	end
	puts t[:name] if transformed_fields.nil? || comments.nil?
	next if transformed_fields.nil? || comments.nil?
	merged = transformed_fields.zip(comments)

	puts '=' * 80
	puts t[:name]
	puts '=' * 80

	merged.each do |entry|
		# puts entry[1]
		# fieldData = entry[0]
		# puts "Field: #{fieldData[0]}  Nillable: #{fieldData[1]} Type: #{fieldData[2] || 'Not defined'}"
		# puts  "-" * 80
	end
end


# z = from_xml(y)[:schema][:element][:complexType][:sequence][:element][:complexType][:sequence][:element][0][:complexType][:sequence][:comment]
# a = from_xml(y)[:schema][:element][:complexType][:sequence][:element][:complexType][:sequence][:element][0][:complexType][:sequence][:element]
# b = a.map do |el|
# 	simpleType = el[:simpleType]
# 	type = nil
# 	type = simpleType[:restriction][:base] if simpleType
# 	[el[:name], el[:nillable], type ]
# end
# pp a
# c = b.zip(z)
# pp from_xml(y)
