# frozen_string_literal: true

require "cartography/version"
require "cartography/inflector/indefinitize"
require "dry/configurable"
require "dry/inflector"
require "logger"

module Cartography
  extend Dry::Configurable

  setting :adapter,   reader: true, default: :here
  setting :logger,    reader: true, default: Logger.new($stdout)
  setting :inflector, reader: true, default: Dry::Inflector.new

  setting :here do
    setting :api_key
  end

  setting :google do
    setting :api_key
  end

  APIError       = Class.new(StandardError)
  MissingAPIKey  = Class.new(StandardError)
  AdapterMissing = Class.new(RuntimeError)
  ServiceMissing = Class.new(RuntimeError)
  ServiceLocked  = Class.new(RuntimeError)
end

Dir["#{__dir__}/cartography/**/*.rb"].each { |f| require f }
