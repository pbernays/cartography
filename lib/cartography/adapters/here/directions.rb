# frozen_string_literal: true

require "cartography/adapters/abstract/service"
require "cartography/adapters/here/request"

module Cartography
  module Adapters
    module Here
      class Directions < Abstract::Service
        service url: "https://router.hereapi.com/v8/routes"
      end
    end
  end
end
