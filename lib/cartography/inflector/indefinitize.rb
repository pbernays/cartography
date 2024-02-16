# frozen_string_literal: true

require "dry/inflector"

module Cartography
  module Inflector
    module Indefinitize
      def naively_indefinitize(input, vowel = "an", consonant = "a")
        "#{input.to_s.match(/^[aeiou]/i) ? vowel : consonant} #{input}"
      end

      alias indefinitize naively_indefinitize
    end

    Dry::Inflector.include Indefinitize
  end
end
