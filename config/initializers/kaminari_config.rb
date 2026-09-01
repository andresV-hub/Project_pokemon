# frozen_string_literal: true

Kaminari.configure do |config|
  # Número de elementos por página cuando no se indica otro.
  config.default_per_page = 16
  # Tope de seguridad para el parámetro `per_page` que llega por la URL.
  config.max_per_page = 60
  # Enlaces de página mostrados a cada lado de la página actual.
  config.window = 2
  config.outer_window = 1
  config.param_name = :page
end
