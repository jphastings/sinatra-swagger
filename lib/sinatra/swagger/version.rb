module Sinatra
  module Swagger
    VERSION = File.read(File.join(__dir__, "../../../VERSION")) rescue "0.0.0"
  end
end