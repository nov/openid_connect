module OpenIDConnect
  module Server
    class IdToken
      class BadRequest < Rack::OAuth2::Server::Abstract::BadRequest; end

      module ErrorMethods
        DEFAULT_DESCRIPTION = {
          :invalid_request => "The request is missing a required parameter.",
          :invalid_id_token => "The ID Token is not valid for the requested resource, is malformed, is in an incorrect format, or is expired."
        }

        def self.included(klass)
          DEFAULT_DESCRIPTION.each do |error, default_description|
            klass.class_eval <<-ERROR
              def #{error}!(description = "#{default_description}", options = {})
                bad_request! :#{error}, description, options
              end
            ERROR
          end
        end

        def bad_request!(error, description = nil, options = {})
          raise BadRequest.new(error, description, options)
        end
      end

      Request.send :include, ErrorMethods
    end
  end
end