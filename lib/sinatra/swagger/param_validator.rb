require "sinatra/swagger/swagger_linked"

module Sinatra
  module Swagger
    module ParamValidator
      def self.registered(app)
        app.register Swagger::SwaggerLinked
        app.helpers Helpers

        app.before do
          next if swagger_spec.nil?
          _, captures, spec = swagger_spec.values
          invalid_content_type(spec['consumes']) if spec['consumes'] && !spec['consumes'].include?(request.content_type)

          # NB. The Validity parser will update the application params with defaults and typing as it goes
          vp = ValidityParser.new(request, params, captures, spec, settings.swagger['definitions'])

          invalid_params(vp.invalidities) if vp.invalidities?
          nil
        end
      end

      module Helpers
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

      class ValidityParser
        attr_reader :request, :params, :captures, :spec, :definitions

        def initialize(request, params, captures, spec, definitions)
          @request = request
          @params = params
          @captures = captures
          @spec = spec
          @definitions = definitions
        end

        def invalidities?
          invalidities.any?
        end

        def invalidities
          return @invalidities unless @invalidities.nil?
          unknown_params = params.keys.select { |k| k.is_a?(String) }

          @invalidities = Hash[(spec['parameters'] || []).map { |details|
            param_name = details['name']
            unknown_params.delete(param_name)

            case details['in']
            when "body"
              body = params[:body]
              next check_json_body(body, param_name, details)

            when "query", "formData"
              parameter = params[param_name]

            when "header"
              normalised_header_name = param_name.tr("-", "_").upcase
              parameter = request.env["HTTP_#{normalised_header_name}"]

            when "path"
              parameter = captures[param_name]

            else
              # other param types aren't dealt with at the moment
              next
            end

            next check_parameter(parameter, param_name, details)
          }.compact]

          unknown_params.each { |p| @invalidities[p] = :unexpected_key } if @invalidities.any?

          @invalidities
        end

        private

        def check_parameter(parameter, param_name, details)
          if !parameter
            return [param_name, :missing] if details['required'] && details['required'] != "false"
            return unless details['default']
            parameter = details['default']
          end

          begin
            parameter = ::Swagger.cast(parameter.to_s, details['type']) if parameter
          rescue ArgumentError
            return [param_name, :incorrect_type]
          end

          if %w{integer number}.include? details['type']
            too_large = details['maximum'] && parameter > details['maximum']
            too_small = details['minimum'] && parameter < details['minimum']
            return [param_name, :out_of_range] if too_large || too_small
          end

          params[param_name] = parameter
        end

        def check_json_body(body, param_name, details)
          request.body.rewind
          params[:body] = request.body.read
          return nil unless request.content_type =~ %r{^application/(?:.+\+)?json}

          begin
            params[:body] = JSON.parse(params[:body])
          rescue JSON::ParserError
            return [param_name, :invalid_json]
          end
          return nil unless details['schema']

          schema = details['schema'].merge('definitions' => definitions)
          errors = JSON::Validator.fully_validate(schema, params[:body])
          return errors.empty? ? nil : [param_name, errors]
        end
      end
    end
  end
end