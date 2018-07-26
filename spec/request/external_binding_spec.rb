require 'spec_helper'

RSpec.describe 'v3 external service bindings' do
  let(:app_model) { VCAP::CloudController::AppModel.make }
  let(:space) { app_model.space }
  let(:user) { make_developer_for_space(space) }
  let(:user_headers) { headers_for(user, user_name: user_name) }
  let(:user_name) { 'room' }

  describe 'POST /v3/external_service_bindings' do
    it 'creates a service binding' do
      stack       = VCAP::CloudController::Stack.make
      post_params = MultiJson.dump({
        name:             'maria',
        space_guid:       space.guid,
        stack_guid:       stack.guid,
        environment_json: { 'KEY' => 'val' },
      })

      post '/v2/apps', post_params, headers_for(user)

      app_model = VCAP::CloudController::ProcessModel.last

      expect(last_response.status).to eq(201), last_response.body

      get '/v2/apps/' + app_model.guid + '/env', nil, user_headers
      expect(last_response.status).to eq(200), last_response.body

      request_body = {
        name: 'rabbit',
        type: 'app',
        data: { credentials: { username: 'admin', password: 'pa$$' } },
        relationships: {
          app: {
            data: {
              guid: app_model.guid
            }
          },
        }
      }.to_json

      post '/v3/external_service_bindings', request_body, user_headers

      expect(last_response.status).to eq(201), last_response.body

      parsed_response = MultiJson.load(last_response.body)
      guid = parsed_response['guid']

      # expect(parsed_response).to be_a_response_like({})
      expect(VCAP::CloudController::ServiceBinding.find(guid: guid)).to be_present

      get '/v2/apps/' + app_model.guid + '/env', nil, user_headers
      expect(last_response.status).to eq(200), last_response.body
    end
  end
end
