$LOAD_PATH << "lib"
require "sinatra/swagger/version"

Gem::Specification.new do |s|
  s.name = "sinatra-swagger"
  s.version = Sinatra::Swagger::VERSION
  s.summary = "Integrates Swagger 2.0 documentation with Sinatra"
  s.description = "Provides helper functions for accessing Swagger documentation from within a Sinatra webapp."
  s.author = "JP Hastings-Spital"
  s.email = "jphastings@gmail.com"
  s.homepage = "http://github.com/jphastings/sinatra-swagger"
  s.license = "MIT"

  s.files = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.md"]

  s.required_ruby_version = '~> 2.0'

  s.add_dependency "json-schema", "~> 2.5", ">= 2.5.1"
  s.add_dependency "sinatra", "~> 1.4"

  s.add_development_dependency "rake", "~> 10.4"
  s.add_development_dependency "rspec", "~> 3.0"
end