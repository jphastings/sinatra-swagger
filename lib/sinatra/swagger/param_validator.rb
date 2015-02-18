require "sinatra/swagger/swagger_linked"

module Sinatra
  module Swagger
    module ParamValidator
      def self.registered(app)
        app.register Swagger::SwaggerLinked

        app.helpers do
          def invalid_params(invalidities)
            error_response(
              'invalid_params',
              'Some of the given parameters were invalid according to the Swagger spec.',
              details: { invalidities: invalidities },
              status: 400
            )
          end

          def invalid_content_type(acceptable)
            error_response(
              'invalid_content',
              'The ',
              details: {
                content_types: {
                  acceptable: acceptable,
                  given: request.content_type
                }
              },
              status: 400
            )
          end

          def error_response(code, dev_message, details: {}, status: 400)
            content_type :json
            halt(status,{
              error: code,
              developerMessage: dev_message,
              details: details
            }.to_json)
          end
        end

        app.before do
          next if swagger_spec.nil?
          _, captures, spec = swagger_spec.values
          invalid_content_type(spec['consumes']) if spec['consumes'] && !spec['consumes'].include?(request.content_type)

          unknown_params = params.keys.select { |k| k.is_a?(String) }

          invalidities = Hash[(spec['parameters'] || []).map { |details|
            param_name = details['name']
            unknown_params.delete(param_name)

            parameter = case details['in']
            when "query"
              params[param_name]
            when "path"
              captures[param_name]
            when "body"
              request.body.rewind
              params[:body] = request.body.read
              next nil unless request.content_type =~ %r{^application/(?:.+\+)?json}

              begin
                params[:body] = JSON.parse(params[:body])
              rescue JSON::ParserError
                next ['POST body', :invalid_json]
              end
              next nil unless details['schema']

              schema = details['schema'].merge('definitions' => settings.swagger['definitions'])
              errors = JSON::Validator.fully_validate(schema, params[:body])
              next errors.empty? ? nil : ['POST body', errors]
            else
              # other param types aren't dealt with at the moment
              next
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

          if invalidities.any?
            unknown_params.each { |p| invalidities[p] = :unexpected_key }
            invalid_params(invalidities)
          end
        end
      end
    end
  end

  register Swagger::ParamValidator
end