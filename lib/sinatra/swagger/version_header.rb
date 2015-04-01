require "sinatra/swagger/swagger_linked"

module Sinatra
  module Swagger
    module VersionHeader
      def self.registered(app)
        app.register Swagger::SwaggerLinked

        app.before do
          headers['X-Application-Version'] = "#{settings.swagger['info']['title']} (#{settings.swagger['info']['version']})"
        end
      end
    end
  end
end