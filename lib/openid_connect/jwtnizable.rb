module OpenIDConnect
  module JWTnizable
    def to_jwt(key, algorithm = :RS256)
      token = JSON::JWT.new as_json
      yield token if block_given?
      if algorithm != :none
        token = token.sign key, algorithm
      end
      token.to_s
    end
  end
end