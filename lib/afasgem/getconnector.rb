# Implements communication with getconnectors
class GetConnector

	# Constructor, takes the name of the connector
	def initialize(name)
		@connectorname = name
		@filters = []
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
		fail ArgumentError.new("Count cannot be lower than 1, #{count} given") unless count > 0
		@result = nil
		@resultcount = count
		return self
	end

	# Set the number of results we want to skip
	# Provides a fluent interface
	def skip(count)
		fail ArgumentError.new("Count cannot be lower than 1, #{count} given") unless count > 0
		@result = nil
		@skip = count
		return self
	end

	# Set the page we want to fetch
	# 1 indexed (i.e. page 1 will fetch result 0 to x)
	# Provides a fluent interface
	def page(number)
		fail ArgumentError.new("Page number cannot be lower than 1, #{number} given") unless number > 0
		@result = nil
		@skip = (number - 1) * get_resultcount
		return self
	end

	# Fetch the next page
	# Provides a fluent interface
	def next
		@skip = (@skip || 0) + get_resultcount
		@result = nil
		return self
	end

	# Fetch the previous page
	# Provides a fluent interface
	def previous
		@result = nil
		@skip = (@skip || 0) - get_resultcount
		@skip = [0, @skip].max
		return self
	end

	# execute the request
	# Provides a fluent interface
	def execute
		result = execute_request(get_resultcount, @skip)

		@data_xml = result[0]
		@result = result[1]
		return self
	end

	# Fetches all results
	# Data is not cached
	def get_all_results
		result_array = []
		skip = 0
		take = 1000
		loop do
			current_result = get_data_from_result(execute_request(take, skip)[1])
			result_array.concat(current_result)
			skip = skip + take
			break if current_result.size != take
		end
		return result_array
	end

	# Adds a filter to the current filter list
	# Provides a fluent interface
	def add_filter(field, operator, value = nil)
		if @filters.size == 0
			@filters.push([])
		end

		# Only the EMPTY and NOT_EMPTY filters should accept a nil value
		if !value
			unless operator == FilterOperators::EMPTY || operator == FilterOperators::NOT_EMPTY
				raise ArgumentError.new('Value can only be empty when using FilterOperator::EMPTY or FilterOperator::NOT_EMPTY')
			end
		end
		@filters.last.push({field: field, operator: operator, value: value})
		return self
	end
	
	# Adds an OR to the current filter list
	# Provides a fluent interface
	def add_or
		@filters.push([]) if @filters.last && @filters.last.size > 0
		return self
	end

	# Clears the filters in place
	# Provides a fluent interface
	def clear_filters
		@filters = []
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
		return get_data_from_result(@result)
	end

	# Returns the raw xml
	def get_data_xml
		execute unless @data_xml
		return @data_xml
	end

	private

	# Actually fires the request
	def execute_request(take, skip = nil)
		message = {
			token: Afasgem.get_token,
			connectorId: @connectorname,
			take: take
		}

		message[:skip] = skip if skip
		filter_string = get_filter_string
		message[:filtersXml] = filter_string if filter_string

		resp = @client.call(:get_data, message: message)
		xml_string = resp.hash[:envelope][:body][:get_data_response][:get_data_result]
		return [xml_string, from_xml(xml_string)]
	end

	# Returns the filter xml in string format
	def get_filter_string
		return nil if @filters.size == 0
		filters = []

		# Loop over each filtergroup
		# All conditions in a filtergroup are combined using AND
		# All filtergroups are combined using OR
		@filters.each_with_index do |filter, index|
			fields = []

			# Loop over all conditions in a filter group
			filter.each do |condition|
				field = condition[:field]
				operator = condition[:operator]
				value = condition[:value]

				# Some filters operate on strings and need wildcards
				# Transform value if needed
				case operator
					when FilterOperators::LIKE
						value = "%#{value}%"
					when FilterOperators::STARTS_WITH
						value = "#{value}%"
					when FilterOperators::NOT_LIKE
						value = "%#{value}%"
					when FilterOperators::NOT_STARTS_WITH
						value = "#{value}%"
					when FilterOperators::ENDS_WITH
						value = "%#{value}"
					when FilterOperators::NOT_ENDS_WITH
						value = "%#{value}"
					when FilterOperators::EMPTY
						# EMPTY and NOT_EMPTY operators require the filter to be in a different format
						# This because they take no value
						fields.push("<Field FieldId=\"#{field}\" OperatorType=\"#{operator}\" />")
						next
					when FilterOperators::NOT_EMPTY
						fields.push("<Field FieldId=\"#{field}\" OperatorType=\"#{operator}\" />")
						next
				end

				# Add this filterstring to filters
				fields.push("<Field FieldId=\"#{field}\" OperatorType=\"#{operator}\">#{value}</Field>")
			end

			# Make sure all filtergroups are OR'ed and add them
			filters.push("<Filter FilterId=\"Filter #{index}\">#{fields.join}</Filter>")
		end

		# Return the whole filterstring
		return "<Filters>#{filters.join}</Filters>"
	end

	# Returns the number of results we want to fetch
	def get_resultcount
		return @resultcount || Afasgem.default_results
	end

	# Returns the actual rows from a parsed response hash
	def get_data_from_result(result)
		return result[:AfasGetConnector][@connectorname.to_sym] || []
	end


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
