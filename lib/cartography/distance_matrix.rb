# frozen_string_literal: true

require "cartography/service"

module Cartography
  class DistanceMatrix < Service
    delegate_to_instance :driving, :walking, :between

    attribute :departure_time, as: :at
    attribute :origins,        as: :from,            array: :locations
    attribute :destinations,   as: :to,              array: :locations
    attribute :bearings,       as: :with_directions, array: true
    attribute :mode,           as: :transit_mode,    assert: ->(mode) { adapter_class.mode? mode }

    def driving
      transit_mode adapter_class.driving_mode
    end

    def walking
      transit_mode adapter_class.walking_mode
    end

    def between(origins, destinations = nil)
      from origins
      to destinations || origins
    end

    def distance(from, to)
      dig from, to, :distance
    end

    def time(from, to)
      dig from, to, :time
    end

    private

    def dig(from, to, type)
      data.dig from.id, to.id, type
    rescue APIError => e
      Cartography.logger.error e.message
      nil
    end
  end
end
