$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "../lib")

module Helpers
  
end

RSpec.configure do |c|
  c.include Helpers
end