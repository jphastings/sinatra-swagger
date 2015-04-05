require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "../lib")
require "rack/test"
require "sinatra/base"
require "sinatra/swagger"

module Helpers
  include Rack::Test::Methods

  def setup_app(&block)
    @app = Class.new(Sinatra::Base) do
      instance_eval(&block)
    end
  end

  def app
    @app
  end

  def use_swagger(hash)
    Tempfile.open('swagger') do |f|
      f.write(YAML.dump(hash))
      f.close
      app.swagger(f.path)
    end
  end

  def use_swagger_paths(hash)
    use_swagger(
      "swagger" => "2.0",
      "info" => {
        "title" => "test app",
        "version" => "1.0.0"
      },
      "paths" => hash
    )
  end
end

RSpec.configure do |c|
  c.include Helpers
end