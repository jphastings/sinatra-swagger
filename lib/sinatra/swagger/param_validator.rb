require "sinatra/swagger/swagger_linked"

module Sinatra
  module Swagger
    module ParamValidator
      def self.registered(app)
        app.register Swagger::SwaggerLinked

        app.before do
          next if swagger_spec.nil?
          _, captures, spec = swagger_spec.values

          invalidities = Hash[(spec['parameters'] || []).map { |details|
            param_name = details['name']

            parameter = case details['in']
            when "query"
              params[param_name]
            when "path"
              captures[param_name]
            else
              raise NotImplementedError, "Can't cope with #{details['in']} parameters right now"
            end

            if !parameter
              next [param_name, :missing] if details['required'] && details['required'] != "false"
              next unless details['default']
              parameter = details['default']
            end

            begin
              parameter = ::Swagger.cast(parameter.to_s, details['type']) if parameter
            rescue ArgumentError
              next [param_name, :incorrect_type]
            end

            if %w{integer number}.include? details['type']
              too_large = details['maximum'] && parameter > details['maximum']
              too_small = details['minimum'] && parameter < details['minimum']
              next [param_name, :out_of_range] if too_large || too_small
            end

            params[param_name] = parameter

            nil
          }.compact]

          halt 400, invalidities.to_json if invalidities.any?
        end
      end
    end
  end

  register Swagger::ParamValidator
end