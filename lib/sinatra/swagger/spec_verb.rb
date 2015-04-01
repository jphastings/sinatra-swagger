require "sinatra/multi_route"
require "sinatra/swagger/swagger_linked"

module Sinatra
  module Swagger
    module SpecVerb
      def self.registered(app)
        app.register Sinatra::MultiRoute
        app.register Swagger::SwaggerLinked

        app.route 'SPEC', '/' do
          content_type "text/vnd.swagger.v2+yaml; charset=utf-8"
          YAML.dump(settings.swagger.spec)
        end
      end
    end
  end
end