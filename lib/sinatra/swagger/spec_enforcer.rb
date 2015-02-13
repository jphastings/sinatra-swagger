require "yaml"
require "swagger/rack"

module Sinatra
  module Swagger
    module SpecEnforcer
      def swagger(filepath)
        set :swagger, ::Swagger::Base.new(filepath)
      end

      def self.registered(app)
        app.helpers Helpers

        app.before do
          spec = swagger_spec
          unless spec.nil?
            _, captures, spec = spec.values

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

      module Helpers
        def swagger_spec
          settings.swagger.request_spec(env: env)
        end
      end
    end
  end

  register Swagger::SpecEnforcer
end