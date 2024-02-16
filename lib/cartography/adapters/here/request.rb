# frozen_string_literal: true

require "cartography/adapters/abstract/request"
require "faraday/follow_redirects"
require "faraday/retry"

module Cartography
  module Adapters
    module Here
      class Request < Abstract::Request
        request_body type: :json
        api_key_required as: "apikey"

        asyncable as: "async" do |params|
          retry_options = {
            max:                 10,
            interval:            0.5,
            interval_randomness: 0.5,
            backoff_factor:      2,
            retry_statuses:      [202, 429],
            retry_if:            ->(env, _) { env.body[:status] != "completed" }
          }

          response = connection.public_send(request_method, url, params)
          response = connection { |c| c.request  :retry, retry_options }.get(response.body[:statusUrl])
          response = connection { |c| c.response :follow_redirects     }.get(response.body[:resultUrl])
          response.body
        end
      end

      class APIError < APIError
        attr_reader :response_body

        def initialize(message)
          JSON.parse(message).tap do |body|
            super(body["cause"] || body["error_description"])
          end
        end
      end
    end
  end
end
