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

    # La curva de experiencia de la especie: `medium`, `slow`, `medium-slow`…
    # Determina cuánto cuesta cada nivel, y hasta ahora se ignoraba y se aplicaba
    # `medium` a todo el mundo.
    def growth_rate
      model.dig('growth_rate', 'name')
    end

    def color
      model.dig('color', 'name')
    end

    def legendary?
      model['is_legendary'] || model['is_mythical'] || false
    end

    # `gender_rate` es la probabilidad de que sea hembra, en octavos: 0 es siempre
    # macho, 8 siempre hembra y −1 significa que la especie no tiene género. La
    # cifra en bruto no dice nada, así que se traduce aquí.
    def gender_label
      rate = model['gender_rate']
      return nil if rate.nil?
      return 'Genderless' if rate.negative?
      return 'Always female' if rate >= 8
      return 'Always male' if rate.zero?

      female = (rate * 100.0 / 8).round
      "#{100 - female}% male · #{female}% female"
    end

    def egg_groups
      Array(model['egg_groups']).map { |group| group['name'].to_s.tr('-', ' ') }
    end

    def base_happiness
      model['base_happiness']
    end

    # Fórmula propia de Pokémon, sin cálculos sobre nivel, HP, etc.
    # Como porcentaje, para enseñarlo en la ficha.
    def capture_rate
      rate = model['capture_rate']
      return nil if rate.nil?

      ((rate * 100) / CAPTURE_RATE_MAX).round
    end

    # El valor tal cual lo da la API, de 0 a 255. Es el que entra en la fórmula de
    # captura del juego, que no trabaja con porcentajes: convertirlo y volver
    # perdería precisión justo donde más se nota, en las especies difíciles —
    # Chansey tiene 30 y Mewtwo 3, y en porcentaje redondean a 12% y 1%.
    def raw_capture_rate
      model['capture_rate']
    end

    private

    def flavor_text_entry
      entries = model['flavor_text_entries']
      return nil if entries.blank?

      entries.find { |entry| entry.dig('language', 'name') == 'en' } || entries.first
    end

  end
end
