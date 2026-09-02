module Shop
  # Objetos de la tienda: precio y efecto, todo en un sitio.
  #
  # Vive como catálogo en código y no en base de datos porque son objetos fijos
  # que forman parte de las reglas del juego, no datos que el usuario administre.
  # Cuando dejen de ser fijos, esta constante es lo único que hay que mover a una
  # tabla.
  #
  # == Los precios son los del juego, y no salen de la API
  #
  # `item.cost` ya no existe en la PokeAPI: se movió a un array `prices` por grupo
  # de versiones, y está incompleto. `great-ball` trae veinticuatro entradas —600
  # en red-blue, que es exactamente el precio de aquí— pero `potion` y `poke-ball`
  # traen el array **vacío**. Así que los precios se escriben aquí, tomados del
  # juego, y de la API se aprovecha lo que sí da entero: el sprite.
  module Catalog

    # `api_name` es el identificador del objeto en la PokeAPI, del que sale el
    # sprite. No siempre coincide con nuestra clave, que usa guión bajo porque es
    # también la que va a la base de datos.
    ITEMS = {
      'poke_ball' => { name: 'Poké Ball', api_name: 'poke-ball', price: 200, category: :ball,
                       multiplier: 1.0,
                       description: 'The standard ball. Works on most wild Pokémon.' },
      'great_ball' => { name: 'Great Ball', api_name: 'great-ball', price: 600, category: :ball,
                        multiplier: 1.5,
                        description: 'Half again as likely to catch as a Poké Ball.' },
      'ultra_ball' => { name: 'Ultra Ball', api_name: 'ultra-ball', price: 1200, category: :ball,
                        multiplier: 2.0,
                        description: 'Twice the catch rate. For the ones that keep breaking free.' },
      'potion' => { name: 'Potion', api_name: 'potion', price: 300, category: :healing,
                    heals: 20,
                    description: 'Restores 20 HP to one Pokémon.' },
      'super_potion' => { name: 'Super Potion', api_name: 'super-potion', price: 700, category: :healing,
                          heals: 50,
                          description: 'Restores 50 HP to one Pokémon.' },
      'revive' => { name: 'Revive', api_name: 'revive', price: 1500, category: :revive,
                    description: 'Brings a fainted Pokémon back with half its HP.' }
    }.freeze

    # Con lo que se empieza: sin bolas, un jugador nuevo no podría capturar nada y
    # necesitaría ganar combates primero, que es justo lo que cuesta al principio.
    STARTING_KIND = 'poke_ball'.freeze
    STARTING_QUANTITY = 5

    # De dónde salen las imágenes de los objetos. Es el repositorio de sprites de
    # la PokeAPI, el mismo del que ya vienen los de los Pokémon.
    SPRITE_BASE = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items'.freeze

    module_function

    def kinds = ITEMS.keys

    def find(kind) = ITEMS[kind.to_s]

    def price(kind) = find(kind)&.fetch(:price)

    # Sin `fetch` a secas: los objetos de curación no tienen multiplicador y
    # `fetch` habría levantado `KeyError` en cuanto el catálogo dejó de ser sólo
    # bolas.
    def multiplier(kind) = find(kind)&.dig(:multiplier) || 1.0

    def name(kind) = find(kind)&.dig(:name)

    def category(kind) = find(kind)&.dig(:category)

    def heals(kind) = find(kind)&.dig(:heals).to_i

    def ball?(kind) = category(kind) == :ball

    def sprite(kind)
      api_name = find(kind)&.dig(:api_name)
      api_name && "#{SPRITE_BASE}/#{api_name}.png"
    end

    # Los que curan, en el orden del catálogo: es el orden de precio y el que
    # espera quien conoce el juego.
    def restorative_kinds
      ITEMS.select { |_, item| %i[healing revive].include?(item[:category]) }.keys
    end

  end
end
