require 'messages/base_message'

module VCAP::CloudController
  class ExternalServiceBindingCreateMessage < BaseMessage
    register_allowed_keys [:type, :name, :relationships, :data]
    ALLOWED_TYPES = ['app'].freeze

    validates_with NoAdditionalKeysValidator, RelationshipValidator, DataValidator

    validates :data, hash: true, allow_nil: true
    validates :type, string: true, presence: true
    validates_inclusion_of :type, in: ALLOWED_TYPES, message: 'type must be app'

    delegate :app_guid, to: :relationships_message

    def credentials
      HashUtils.dig(data, :credentials)
    end

    def relationships_message
      @relationships_message ||= Relationships.new(relationships.deep_symbolize_keys)
    end

    class Relationships < BaseMessage
      register_allowed_keys [:service_instance, :app]

      def app_guid
        HashUtils.dig(app, :data, :guid)
      end

      validates_with NoAdditionalKeysValidator

      validates :app, presence: true, allow_nil: false, to_one_relationship: true
    end

    class Data < BaseMessage
      register_allowed_keys [:credentials]

      validates_with NoAdditionalKeysValidator
    end
  end
end
