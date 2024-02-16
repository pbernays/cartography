# frozen_string_literal: true

require "cartography/adapters/abstract/service"
require "cartography/adapters/google/request"

module Cartography
  module Adapters
    module Google
      class DistanceMatrix < Abstract::Service
        MODES = %i[driving walking bicycling transit].freeze

        service url: "https://maps.googleapis.com/maps/api/distancematrix/json"

        class << self
          def driving_mode
            :driving
          end

          def walking_mode
            :walking
          end
        end

        def call(**params)
          return {} unless params[:origins]&.any?

          params[:destinations] = params[:origins] unless params[:destinations]&.any?

          request.call(normalize_params(**params)) do |body|
            rows = extract_data(body).map do |elements|
              match_with_locations elements, params[:destinations]
            end

            match_with_locations rows, params[:origins]
          end
        end

        private

        def normalize_params(
          mode: nil,
          origins: nil,
          destinations: nil,
          departure_time: nil,
          **
        )
          {
            mode:           mode || self.class.driving_mode,
            departure_time: departure_time&.to_i,
            origins:        normalize(origins),
            destinations:   normalize(destinations)
          }.delete_if { |_, v| v.blank? }
        end

        def normalize(locations)
          locations.map do |location|
            [location.lat, location.lon].join(",")
          end.join("|")
        end

        def extract_data(json)
          json[:rows].map do |row|
            row[:elements].map do |element|
              next unless element[:status] == "OK"

              {
                distance:        element.dig(:distance, :value),
                time:            element.dig(:duration, :value),
                time_in_traffic: element.dig(:duration_in_traffic, :value)
              }
            end
          end
        end

        def match_with_locations(data, locations)
          locations.map(&:id).zip(data).to_h
        end
      end
    end
  end
end
