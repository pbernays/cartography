# frozen_string_literal: true

require "cartography/adapters/abstract/service"
require "cartography/adapters/here/request"

module Cartography
  module Adapters
    module Here
      class Isoline < Abstract::Service
        service url: "https://isoline.router.hereapi.com/v8/isolines"
      end
    end
  end
end
