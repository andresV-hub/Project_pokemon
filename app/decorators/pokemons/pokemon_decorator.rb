module Pokemons
  class PokemonDecorator < ApplicationDecorator

  	decorates :pokemon

  	delegate_all

  	def self.collection_decorator_class
  		ApplicationCollectionDecorator
  	end

  	# Misma escala que en la Pokédex: las barras de un Pokémon capturado y las
  	# de una especie del catálogo tienen que ser comparables (styles.md §6.7).
  	STAT_MAX = ::Pokedex::PokedexDecorator::STAT_MAX

  	# ---- Presentación (styles.md §6) --------------------------------------

  	def dex_number
  		format('#%04d', num_pokedex.to_i)
  	end

  	# En el PC sólo se guarda el tipo primario, y capitalizado. El modificador
  	# `dex-type--{tipo}` necesita la clave inglesa en minúsculas (styles.md §6.2).
  	def type_slug
  		slug = model.type_of_pokemon.to_s.downcase.strip
  		slug.presence || 'normal'
  	end

  	def type_slugs
  		[type_slug]
  	end

  	def type_names
  		[model.type_of_pokemon.to_s.capitalize.presence].compact
  	end

  	def stat_list
  		[
  			{ key: 'hp', label: 'HP', value: model.hp.to_i },
  			{ key: 'attack', label: 'Attack', value: model.atack.to_i },
  			{ key: 'defense', label: 'Defense', value: model.defense.to_i },
  			{ key: 'special-attack', label: 'Sp. Atk', value: model.special_atack.to_i },
  			{ key: 'special-defense', label: 'Sp. Def', value: model.special_defense.to_i },
  			{ key: 'speed', label: 'Speed', value: model.speed.to_i }
  		]
  	end

  	def move_list
  		[model.atack0, model.atack1, model.atack2, model.atack3]
  			.compact_blank
  			.map { |move| move.to_s.tr('-', ' ').capitalize }
  	end

  	# El apodo es lo que el usuario ve primero: es suyo (styles.md §6.6).
  	def display_name
  		model.nickname.presence || model.name.to_s.capitalize
  	end

  	def species_name
  		model.name.to_s.capitalize
  	end

  	def artwork
  		model.image
  	end

  	# Experiencia acumulada que hará falta para el siguiente nivel: sola, la
  	# cifra de experiencia no dice nada sobre lo cerca que se está.
  	def next_level_experience
  		::Pokemons::LevelStats.experience_for(model.level.to_i + 1)
  	end

  	# La curva es `n³` sobre el total acumulado, así que la cifra en bruto
  	# tampoco dice nada: 179 de experiencia no parece «casi 6» hasta que sabes
  	# que el nivel 5 empezaba en 125 y el 6 llega en 216. Esto es lo que
  	# convierte esos tres números en una fracción del nivel en curso.
  	def experience_percent
  		# Al tope la barra se llena. La curva sigue dando un nivel 101 que nadie
  		# alcanzará, y medir contra él dejaba la barra a cero justo en el punto
  		# donde ya no queda nada por recorrer.
  		return 100 if max_level?

  		floor = ::Pokemons::LevelStats.experience_for(model.level.to_i)
  		span = next_level_experience - floor
  		return 100 if span <= 0

  		(((model.experience.to_i - floor) * 100.0) / span).clamp(0, 100).round
  	end

  	# Lo que falta, que es la pregunta que se hace de verdad quien mira la barra.
  	def experience_to_next_level
  		return 0 if max_level?

  		[next_level_experience - model.experience.to_i, 0].max
  	end

  	def max_level?
  		model.level.to_i >= ::Pokemons::LevelStats::MAX_LEVEL
  	end

  	def sprite_alt
  		"#{species_name}, Pokédex ##{num_pokedex}"
  	end

  end
end
