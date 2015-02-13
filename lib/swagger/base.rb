require "json-schema"

module Swagger
  # Casts a string value to the ruby datatype as definied in the swagger spec
  def self.cast(value, type = "string")
    raise ArgumentError, "#{value} is not a string" unless value.is_a?(String)
    case type
    when "string"
      value
    when "integer"
      raise ArgumentError, "#{value} is not an integer" unless value =~ /^-?\d+$/
      value.to_i
    when "number"
      raise ArgumentError, "#{value} is not a float" unless value =~ /^-?\d+(?:\.\d+)?$/
      value.to_f
    else
      raise NotImplementedError
    end
  end

  class Base
    # Pre-load JSON-schema files used for validation
    Dir.glob(File.join(__dir__, "../../schema/*-schema.json")) do |schema|
      data = JSON.parse(File.read(schema))
      JSON::Validator.add_schema(JSON::Schema.new(data, data['id']))
    end

    def initialize(data)
      @spec = data
      JSON::Validator.validate!({ "$ref" => "http://swagger.io/v2/schema.json#" }, @spec)
    end

    def self.from_file(filepath)
      new(YAML.load(open(filepath)))
    end

    def [](key)
      @spec[key]
    end
  end
end