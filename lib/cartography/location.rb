# frozen_string_literal: true

require "cartography/types"
require "dry/struct"
require "dry/types"

module Cartography
  class Location < Dry::Struct
    attribute :id,  Types::Strict::Integer | Types::Strict::String
    attribute :lat, Types::Coercible::Float.constrained(gteq:  -90, lteq:  90)
    attribute :lon, Types::Coercible::Float.constrained(gteq: -180, lteq: 180)

    CoercionError = Class.new(StandardError)

    class << self
      def from(obj)
        @constructor ||= Dry::Types::Constructor.new(Location) do |obj| # rubocop:disable Lint/ShadowingOuterLocalVariable
          discover =
            case obj
            when Array
              ->(*) { obj.shift }
            when Hash
              ->(*keys) {
                sym_obj = obj.transform_keys(&:to_sym)
                sym_obj[discover!(obj, keys) { |key| sym_obj.key? key }]
              }
            else
              ->(*methods) {
                obj.public_send(discover!(obj, methods) { |m| obj.respond_to? m })
              }
            end

          {
            id:  discover.call(:id, :uuid),
            lat: discover.call(:latitude, :lat),
            lon: discover.call(:longitude, :lon, :lng, :long)
          }
        end

        @constructor.call obj
      end

      private

      def discover!(obj, attrs, &block)
        attrs.find(&block) or
          fail CoercionError, "couldn't find #{Cartography.inflector.indefinitize(attrs.first)} in #{obj}"
      end
    end
  end
end
