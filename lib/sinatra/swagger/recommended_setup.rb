require "sinatra/swagger/param_validator"
require "sinatra/swagger/spec_enforcer"
require "sinatra/swagger/spec_verb"
require "sinatra/swagger/version_header"

module Sinatra
  module Swagger
    module RecommendedSetup
      def self.registered(app)
        app.register Sinatra::Swagger::SpecEnforcer unless app.production?
        app.register Sinatra::Swagger::ParamValidator
        app.register Sinatra::Swagger::SpecVerb
        app.register Sinatra::Swagger::VersionHeader
      end
    end
  end

  register Swagger::RecommendedSetup
end