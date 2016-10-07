require "swagger/base"

module Swagger
  module RackHelpers
    def request_spec(env: nil)
      path = env['REQUEST_PATH'] || env['PATH_INFO']
      verb = env['REQUEST_METHOD'].downcase
      matching_paths = (@spec['paths'] || {}).map { |spec_path, spec|
        next unless spec[verb]
        matches = match_string(spec_path, path)
        next if matches.nil?
        {
          path: spec_path,
          captures: matches,
          spec: spec[verb]
        }
      }.compact

      case matching_paths.size
      when 0
        return nil
      when 1
        return matching_paths.first
      else
        spec_paths = matching_paths.map { |p| p[:path] }
        raise "Your API documentation is non-deterministic for the path: #{path} (#{spec_paths.join(', ')})"
      end
    end

    private

    def match_string(bracketed_string, match_string)
      re = bracketed_string.gsub(/\{([^}]+)\}/, "(?<\\1>.+?)")
      matches = Regexp.new("^#{re}$").match(match_string)
      return nil if matches.nil?
      captures = matches.captures
      Hash[matches.names.zip(captures)]
    end
  end

  Base.send(:include, RackHelpers)
end