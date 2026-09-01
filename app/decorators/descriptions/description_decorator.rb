module Descriptions
  class DescriptionDecorator < ApplicationDecorator

    # La API sólo trae `habitat` para las primeras generaciones y las entradas
    # de texto vienen en varios idiomas, así que hay que elegir y proteger.
    UNKNOWN = 'Unknown'.freeze
    CAPTURE_RATE_MAX = 255.0

    def description
      entry = flavor_text_entry
      return '' if entry.nil?

      entry['flavor_text'].to_s.tr("\f\n\r", ' ').squeeze(' ').strip
    end

    def habitat
      model.dig('habitat', 'name')&.capitalize || UNKNOWN
    end

    def base_happiness
      model['base_happiness']
    end

    # Fórmula propia de Pokémon, sin cálculos sobre nivel, HP, etc.
    def capture_rate
      rate = model['capture_rate']
      return nil if rate.nil?

      ((rate * 100) / CAPTURE_RATE_MAX).round
    end

    private

    def flavor_text_entry
      entries = model['flavor_text_entries']
      return nil if entries.blank?

      entries.find { |entry| entry.dig('language', 'name') == 'en' } || entries.first
    end

  end
end
