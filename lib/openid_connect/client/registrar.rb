module OpenIDConnect
  class Client
    class Registrar
      include ActiveModel::Validations, AttrRequired, AttrOptional

      class RegistrationFailed < HttpError; end

      attr_required :endpoint
      attr_optional(
        :type,
        :client_id,
        :client_secret,
        :access_token,
        :contacts,
        :application_type,
        :application_name,
        :logo_url,
        :redirect_uris,
        :token_endpoint_auth_type,
        :policy_url,
        :jwk_url,
        :jwk_encryption_url,
        :x509_url,
        :x509_encryption_url,
        :sector_identifier_url,
        :user_id_type,
        :require_signed_request_object,
        :userinfo_signed_response_algs,
        :userinfo_encrypted_response_algs,
        :id_token_signed_response_algs,
        :id_token_encrypted_response_algs
      )

      validates :type,                  :presence => true
      validates :client_id,             :presence => {:if => lambda { |c| c.type.to_s == 'client_update' }}
      validates :sector_identifier_url, :presence => {:if => :sector_identifier_required?}

      validates :type,             :inclusion => {:in => ['client_associate', 'client_update']}
      validates :application_type, :inclusion => {:in => ['native', 'web']},      :allow_nil => true
      validates :user_id_type,     :inclusion => {:in => ['pairwise', 'public']}, :allow_nil => true
      validates :token_endpoint_auth_type, :inclusion => {
        :in => ['client_secret_post', 'client_secret_basic', 'client_secret_jwt', 'private_key_jwt']
      }, :allow_nil => true

      validates(
        :logo_url,
        :policy_url,
        :jwk_url,
        :jwk_encryption_url,
        :x509_url,
        :x509_encryption_url,
        :sector_identifier_url,
        :url => true, :allow_nil => true
      )

      # TODOs
      # validate :validate_contacts
      # validate :validate_redirect_uris
      # validate :validate_key_urls
      # validate :validate_signature_algorithms
      # validate :validate_encription_algorithms

      def initialize(endpoint, attributes = {})
        @endpoint = endpoint
        optional_attributes.each do |_attr_|
          self.send "#{_attr_}=", attributes[_attr_].try(:to_s)
        end
        attr_missing!
      end

      def sector_identifier
        if sector_identifier_url
          URI.parse(sector_identifier_url).host rescue nil
        else
          hosts = Array(redirect_uris).collect do |redirect_uri|
            URI.parse(redirect_uri).host rescue nil
          end.compact.uniq
          if hosts.size == 1
            hosts.first
          else
            nil
          end
        end
      end

      def as_json(options = {})
        validate!
        (optional_attributes - [:access_token]).inject({}) do |hash, _attr_|
          value = self.send(_attr_)
          hash.merge! _attr_ => case value
          when Array
            value.collect(&:to_s).join(' ')
          else
            value
          end
        end.delete_if do |key, value|
          value.nil?
        end
      end

      def associate!
        self.type = 'client_associate'
        post!
      end

      def update!
        self.type = 'client_update'
        post!
      end

      def validate!
        valid? or raise ValidationFailed.new(errors)
      end

      private

      def sector_identifier_required?
        user_id_type == 'pairwise' &&
        sector_identifier.blank?
      end

      def post!
        handle_response do
          http_client.post endpoint, as_json
        end
      end

      def http_client
        case access_token
        when nil
          OpenIDConnect.http_client
        when Rack::OAuth2::AccessToken::Bearer
          access_token
        else
          Rack::OAuth2::AccessToken::Bearer.new(
            :access_token => access_token
          )
        end
      end

      def handle_response
        response = yield
        case response.status
        when 200..201
          handle_success_response response
        else
          handle_error_response response
        end
      end

      def handle_success_response(response)
        credentials = JSON.parse(response.body).with_indifferent_access
        Client.new(
          :identifier => credentials[:client_id],
          :secret     => credentials[:client_secret],
          :expires_in => credentials[:expires_in]
        )
      end

      def handle_error_response(response)
        raise RegistrationFailed.new(response.status, 'Client Registration Failed', response)
      end
    end
  end
end