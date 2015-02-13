module Sinatra
  module Swagger
    VERSION = File.read(File.join(File.dirname(__FILE__), "../../../VERSION")) rescue "0.0.0"
  end
end