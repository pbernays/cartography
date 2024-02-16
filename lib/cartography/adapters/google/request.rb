# frozen_string_literal: true

require "cartography/adapters/abstract/request"

module Cartography
  module Adapters
    module Google
      class Request < Abstract::Request
        request_body type: :url_encoded
        api_key_required as: "key"
      end
    end
  end
end
