# frozen_string_literal: true

require "cartography/adapters/abstract/service"
require "cartography/adapters/here/request"
require "time"

module Cartography
  module Adapters
    module Here
      class DistanceMatrix < Abstract::Service
        MODES = %i[car truck pedestrian bicycle scooter taxi bus private_bus].freeze
        MARGIN = 20_000 # metres
        ROUTING_MODES = %i[distances travelTimes].freeze

        service url: "https://matrix.router.hereapi.com/v8/matrix", method: :post

        class << self
          def driving_mode
            :bus
          end

          def walking_mode
            :pedestrian
          end
        end

        def call(**params)
          return {} unless params[:origins]&.any?

          params[:destinations] = params[:origins] unless params[:destinations]&.any?

          request.call(normalize_params(**params)) do |body|
            grouped_destinations = groups(extract_data(body), params[:origins].size).map do |destination|
              match_with_locations destination, params[:destinations]
            end

            match_with_locations grouped_destinations, params[:origins]
          end
        end

        private

        def normalize_params(
          mode: nil,
          origins: nil,
          destinations: nil,
          departure_time: nil,
          bearings: nil,
          **
        )
          mode ||= self.class.driving_mode
          departure_time ||= Time.now

          {
            transportMode:    Cartography.inflector.camelize_lower(mode),
            origins:          normalize(origins, bearings),
            destinations:     normalize(destinations, nil),
            departureTime:    departure_time.iso8601,
            matrixAttributes: ROUTING_MODES,
            regionDefinition: {
              type:   "autoCircle",
              margin: MARGIN
            }
          }.delete_if { |_, value| value.blank? }
        end

        def normalize(locations, bearings)
          unless bearings&.any?
            return locations.map do |location|
              { lat: location.lat, lng: location.lon }
            end
          end

          locations.map.with_index do |location, i|
            { lat: location.lat, lng: location.lon }.tap do |hash|
              hash[:course] = bearings[i] if (0..360).cover? bearings[i]
            end
          end
        end

        def extract_data(json)
          json[:matrix][:travelTimes].map.with_index do |travel_time, index|
            { time: travel_time }.tap do |hash|
              hash[:distance] = json[:matrix][:distances][index]
            end
          end
        end

        def match_with_locations(data, locations)
          locations.map(&:id).zip(data).to_h
        end

        def groups(data, number)
          groups = []
          start  = 0
          div    = data.size.div(number)
          mod    = data.size % number

          number.times do |index|
            length = div + (mod > index ? 1 : 0)
            groups << last_group = data.slice(start, length)
            last_group << nil if mod.positive? && length == div
            start += length
          end

          groups
        end
      end
    end
  end
end
