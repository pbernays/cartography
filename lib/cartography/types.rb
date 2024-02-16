# frozen_string_literal: true

require "dry/struct"
require "dry/types"

module Cartography
  module Types
    include Dry.Types(:strict, :coercible)
  end
end
