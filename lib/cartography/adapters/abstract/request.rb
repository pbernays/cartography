# frozen_string_literal: true

require "faraday"

module Cartography
  module Adapters
    module Abstract
      class Request
        class << self
          attr_reader :api_key_as, :async_as, :async_request_proc, :request_body_type

          @api_key_required = false

          def api_key_required(as:)
            @api_key_required = true
            @api_key_as = as
          end

          def api_key_required?
            !!@api_key_required
          end

          def asyncable(as:, &block)
            @async_as = as
            @async_request_proc = block
          end

          def asyncable?
            !!@async_request_proc
          end

          def request_body(type:)
            @request_body_type = type
          end

          def new(*args)
            if self == Abstract::Request
              fail NotImplementedError, "#{self} is an abstract class and cannot be instantiated."
            end

            super(*args)
          end
        end

        attr_reader :url, :request_method, :api_key, :async

        def initialize(url, method, api_key, async)
          unless Faraday::Connection::METHODS.include? method.to_s.to_sym
            fail ArgumentError, "Unknown http method: #{method}"
          end

          @url = url
          @request_method = method
          @api_key = api_key
          @async = async && self.class.asyncable?
        end

        def call(params)
          if self.class.api_key_required? and not api_key
            Cartography.logger.error "No API key supplied"
            fail MissingAPIKey
          end

          body = perform_request(params)
          block_given? ? yield(body) : body
        end

        private

        def perform_request(params)
          if async
            instance_exec params, &self.class.async_request_proc
          else
            connection.public_send(request_method, url, params).body
          end
        rescue StandardError => e
          error_class = APIError

          if self.class.module_parent.const_defined? "APIError"
            error_class = self.class.module_parent.const_get("APIError")
          end

          raise error_class, e.response_body
        end

        def connection
          Faraday.new do |f|
            f.adapter  Faraday.default_adapter

            f.request  self.class.request_body_type

            f.response :json, content_type: /\bjson$/, parser_options: { symbolize_names: true }
            f.response :raise_error
            f.response :logger do |log|
              log.filter(/([kK]ey=)([^&]+)/, '\1[FILTERED]')
            end

            f.params = {}
            f.params[self.class.api_key_as] = api_key if self.class.api_key_as
            f.params[self.class.async_as]   = async   if self.class.async_as
          end.tap { |f| yield f if block_given? }
        end
      end
    end
  end
end
