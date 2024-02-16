# frozen_string_literal: true

require "cartography/adapters/abstract/service"
require "cartography/adapters/google/request"

module Cartography
  module Adapters
    module Google
      class Isoline < Abstract::Service
        service url: "https://maps.googleapis.com/maps/api/directions/json"
      end
    end
  end
end
