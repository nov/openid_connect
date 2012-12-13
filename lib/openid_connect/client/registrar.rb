module OpenIDConnect
  class Client
    class Registrar
      include ActiveModel::Validations, AttrRequired, AttrOptional

      class RegistrationFailed < HttpError; end

      singular_attributes = [
        :type,
        :client_id,
        :client_secret,
        :access_token,
        :application_type,
        :application_name,
        :logo_url,
        :token_endpoint_auth_type,
        :policy_url,
        :jwk_url,
        :jwk_encryption_url,
        :x509_url,
        :x509_encryption_url,
        :sector_identifier_url,
        :user_id_type,
        :request_object_signing_alg,
        :userinfo_signed_response_alg,
        :userinfo_encrypted_response_alg,
        :userinfo_encrypted_response_enc,
        :id_token_signed_response_alg,
        :id_token_encrypted_response_alg,
        :id_token_encrypted_response_enc,
        :default_max_age,
        :require_auth_time,
        :default_acr
      ]
      plurar_attributes = [
        :contacts,
        :redirect_uris
      ]
      attr_required :endpoint
      attr_optional *(singular_attributes + plurar_attributes)

      plurar_attributes.each do |_attr_|
        define_method "#{_attr_}_with_split" do
          value = self.send("#{_attr_}_without_split")
          case value
          when String
            value.split(' ')
          else
            value
          end
        end
        alias_method_chain _attr_, :split
      end

      validates :type,                  presence: true
      validates :client_id,             presence: {if: ->(c) { ['client_update', 'rotate_secret'].include?(c.type.to_s) }}
      validates :sector_identifier_url, presence: {if: :sector_identifier_required?}

      validates :type,             inclusion: {in: ['client_associate', 'rotate_secret', 'client_update']}
      validates :application_type, inclusion: {in: ['native', 'web']},      allow_nil: true
      validates :user_id_type,     inclusion: {in: ['pairwise', 'public']}, allow_nil: true
      validates :token_endpoint_auth_type, inclusion: {
        in: ['client_secret_post', 'client_secret_basic', 'client_secret_jwt', 'private_key_jwt']
      }, allow_nil: true

      validates(
        :logo_url,
        :policy_url,
        :jwk_url,
        :jwk_encryption_url,
        :x509_url,
        :x509_encryption_url,
        :sector_identifier_url,
        url: true,
        allow_nil: true
      )

      validate :validate_contacts
      validate :validate_redirect_uris
      validate :validate_key_urls
      validate :validate_signature_algorithms
      validate :validate_encription_algorithms

      def initialize(endpoint, attributes = {})
        @endpoint = endpoint
        optional_attributes.each do |_attr_|
          value = if _attr_ == :access_token
            attributes[_attr_]
          else
            attributes[_attr_].try(:to_s)
          end
          self.send "#{_attr_}=", value
        end
        attr_missing!
      end

      def sector_identifier
        if valid_uri?(sector_identifier_url)
          URI.parse(sector_identifier_url).host
        else
          hosts = Array(redirect_uris).collect do |redirect_uri|
            if valid_uri?(redirect_uri, nil)
              URI.parse(redirect_uri).host
            else
              nil
            end
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

      def rotate_secret!
        self.type = 'rotate_secret'
        post!
      end

      def update!
        self.type = 'client_update'
        post!
      end

      def validate!
        valid? or raise ValidationFailed.new(self)
      end

      private

      def sector_identifier_required?
        user_id_type == 'pairwise' &&
        sector_identifier.blank?
      end

      def valid_uri?(uri, schemes = ['http', 'https'])
        # NOTE: specify nil for schemes to allow any schemes
        URI::regexp(schemes).match(uri).present? &&
        URI.parse(uri).fragment.blank?
      end

      def validate_contacts
        if contacts
          include_invalid = contacts.any? do |contact|
            begin
              mail = Mail::Address.new(contact)
              mail.address != contact || mail.domain.split(".").length <= 1
            rescue
              :invalid
            end
          end
          errors.add :contacts, 'includes invalid email' if include_invalid
        end
      end

      def validate_redirect_uris
        if redirect_uris
          include_invalid = redirect_uris.any? do |redirect_uri|
            !valid_uri?(redirect_uri, nil)
          end
          errors.add :redirect_uris, 'includes invalid URL' if include_invalid
        end
      end

      def validate_key_urls
        # TODO
      end

      def validate_signature_algorithms
        # TODO
      end

      def validate_encription_algorithms
        # TODO
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
            access_token: access_token
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
        credentials = JSON.parse response.body, symbolize_names: true
        Client.new(
          identifier: credentials[:client_id],
          secret:     credentials[:client_secret],
          expires_in: credentials[:expires_in]
        )
      end

      def handle_error_response(response)
        raise RegistrationFailed.new(response.status, 'Client Registration Failed', response)
      end
    end
  end
end