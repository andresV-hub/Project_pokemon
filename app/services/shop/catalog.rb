module Shop
  # Objetos de la tienda: precio y efecto, todo en un sitio.
  #
  # Vive como catálogo en código y no en base de datos porque son tres objetos
  # fijos que forman parte de las reglas del juego, no datos que el usuario
  # administre. Cuando dejen de ser fijos, esta constante es lo único que hay que
  # mover a una tabla.
  module Catalog

    ITEMS = {
      'poke_ball' => { name: 'Poké Ball', price: 200, multiplier: 1.0,
                       description: 'The standard ball. Works on most wild Pokémon.' },
      'great_ball' => { name: 'Great Ball', price: 600, multiplier: 1.5,
                        description: 'Half again as likely to catch as a Poké Ball.' },
      'ultra_ball' => { name: 'Ultra Ball', price: 1200, multiplier: 2.0,
                        description: 'Twice the catch rate. For the ones that keep breaking free.' }
    }.freeze

    # Con lo que se empieza: sin bolas, un jugador nuevo no podría capturar nada
    # y necesitaría ganar combates primero, que es justo lo que cuesta al
    # principio.
    STARTING_KIND = 'poke_ball'.freeze
    STARTING_QUANTITY = 5

    module_function

    def kinds = ITEMS.keys

    def find(kind) = ITEMS[kind.to_s]

    def price(kind) = find(kind)&.fetch(:price)

    def multiplier(kind) = find(kind)&.fetch(:multiplier) || 1.0

    def name(kind) = find(kind)&.fetch(:name)

  end
end
