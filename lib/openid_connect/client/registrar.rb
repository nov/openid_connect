module OpenIDConnect
  class Client
    class Registrar
      include ActiveModel::Validations, AttrRequired, AttrOptional

      class ValidationFailed < Exception
        attr_reader :errors

        def initialize(errors)
          super errors.full_messages.to_sentence
          @errors = errors
        end
      end
      class RegistrationFailed < HttpError; end

      attr_required :endpoint
      attr_optional(
        :type,
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
      validates :sector_identifier_url, :presence => {:if => lambda { |c| c.user_id_type.to_s == 'pairwise' }}

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
      # validate :validate_key_urls, :unless => :skip_key_url_validation?
      # validate :validate_signature_algorithms
      # validate :validate_encription_algorithms

      def initialize(endpoint, attributes = {})
        @endpoint = endpoint
        optional_attributes.each do |_attr_|
          self.send "#{_attr_}=", attributes[_attr_].try(:to_s)
        end
        attr_missing!
      end

      def associate!
        self.type = 'client_associate'
        post!
      end

      def update!
        self.type = 'client_update'
        post!
      end

      def skip_key_url_validation!
        # Key URLs "SHOULD" be validated
        @skip_key_url_validation = true
      end

      def skip_key_url_validation?
        @skip_key_url_validation
      end

      private

      def validate!
        valid? or raise ValidationFailed.new(errors)
      end

      def post!
        validate!
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