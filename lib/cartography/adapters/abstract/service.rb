# frozen_string_literal: true

require "cartography/adapters/abstract/request"

module Cartography
  module Adapters
    module Abstract
      class Service
        class << self
          attr_reader :request, :request_class

          def service(url:, method: :get, api_key: nil, async: false)
            define_method :request do
              request_class = self.class.module_parent.const_get("Request")
              request_class.new(url, method, @api_key || api_key, @async || async)
            end
          end

          def mode?(mode)
            constants.include? :MODES and const_get("MODES").include? mode.to_s.to_sym
          end
        end

        def initialize(api_key: nil, async: nil)
          @api_key = api_key
          @async = async
        end
      end
    end
  end
end
