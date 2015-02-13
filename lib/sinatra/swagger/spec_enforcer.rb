require "sinatra/swagger/param_validator"

module Sinatra
  module Swagger
    module SpecEnforcer
      def self.registered(app)
        app.register Swagger::SwaggerLinked

        app.after do
          next unless response.content_type =~ %r{^application/(?:.+\+)?json$}
          next unless body = JSON.parse(response.body.first) rescue nil
          next if swagger_spec.nil?
          schema = schema_from_spec_at("responses/#{response.status}/schema")
          next if schema.nil?
          begin
            JSON::Validator.validate!(schema, body)
          rescue JSON::Schema::ValidationError => e
            e.message = "Response JSON did not match the Swagger schema: #{e.message}"
            raise e
          end
        end
      end
    end
  end
end