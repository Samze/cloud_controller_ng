require 'diego/bbs/bbs'
require 'diego/errors'
require 'diego/routes'

module Diego
  class Client
    def initialize(url:, ca_cert_file:, client_cert_file:, client_key_file:)
      @client = build_client(url, ca_cert_file, client_cert_file, client_key_file)
    end

    def ping
      response = with_request_error_handling do
        client.post(Routes::PING)
      end

      validate_status!(response: response, statuses: [200])
      protobuf_decode!(response.body, Bbs::Models::PingResponse)
    end

    def desire_task(task)
      encoded_task = protobuf_encode!(task)

      response = with_request_error_handling do
        client.post(Routes::DESIRE_TASK, encoded_task, protobuf_header)
      end

      validate_status!(response: response, statuses: [200])
      protobuf_decode!(response.body, Bbs::Models::TaskResponse)
    end

    def task_by_guid(task_guid)
      request         = Bbs::Models::TaskByGuidRequest.new(task_guid: task_guid)
      encoded_request = protobuf_encode!(request)

      response = with_request_error_handling do
        client.post(Routes::TASK_BY_GUID, encoded_request, protobuf_header)
      end

      validate_status!(response: response, statuses: [200])
      protobuf_decode!(response.body, Bbs::Models::TaskResponse)
    end

    def tasks(domain: nil, cell_id: nil)
      request         = Bbs::Models::TasksRequest.new(domain: domain, cell_id: cell_id)
      encoded_request = protobuf_encode!(request)

      response = with_request_error_handling do
        client.post(Routes::LIST_TASKS, encoded_request, protobuf_header)
      end

      validate_status!(response: response, statuses: [200])
      protobuf_decode!(response.body, Bbs::Models::TasksResponse)
    end

    private

    attr_reader :client

    def with_request_error_handling(&blk)
      yield
    rescue => e
      raise ClientError.new(e.message)
    end

    def protobuf_encode!(object)
      object.encode.to_s
    rescue => e
      raise EncodeError.new(e.message)
    end

    def validate_status!(response:, statuses:)
      raise ClientError.new("failed with status: #{response.status}, body: #{response.body}") unless statuses.include?(response.status)
    end

    def protobuf_header
      { 'Content-Type' => 'application/x-protobuf' }
    end

    def protobuf_decode!(message, protobuf_decoder)
      protobuf_decoder.decode(message)
    rescue => e
      raise DecodeError.new(e.message)
    end

    def build_client(url, ca_cert_file, client_cert_file, client_key_file)
      client = HTTPClient.new(base_url: url)
      client.ssl_config.set_client_cert_file(client_cert_file, client_key_file)
      client.ssl_config.set_trust_ca(ca_cert_file)
      client
    end
  end
end