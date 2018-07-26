require 'fetchers/service_binding_create_fetcher'
require 'fetchers/service_binding_list_fetcher'
require 'presenters/v3/service_binding_presenter'
require 'messages/external_service_binding_create_message'
require 'messages/service_bindings_list_message'
require 'actions/service_binding_create'
require 'actions/service_binding_delete'
require 'controllers/v3/mixins/app_sub_resource'

class ExternalServiceBindingsController < ApplicationController
  include AppSubResource

  def external_create
    message = ExternalServiceBindingCreateMessage.new(params[:body])
    unprocessable!(message.errors.full_messages) unless message.valid?

    app = AppModel.first(guid: message.app_guid)
    app_not_found! unless app
    unauthorized! unless permission_queryer.can_write_to_space?(app.space.guid)

    service_instance = UserProvidedServiceInstance.new(
      name: message.name,
      space_guid: app.space.guid,
      credentials: message.credentials,
    )
    service_instance.save

    service_binding = ServiceBinding.new(
      app:              app,
      credentials:      message.credentials,
      type:             message.type,
      name:             message.name,
      service_instance: service_instance
    )
    service_binding.save

    render status: :created, json: Presenters::V3::ServiceBindingPresenter.new(service_binding)
  end

  private

  def binding_not_found!
    resource_not_found!(:service_binding)
  end
end
