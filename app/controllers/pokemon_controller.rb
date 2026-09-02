class PokemonController < ApplicationController

	# Pokémon capturados por el usuario, paginados con Kaminari sobre la consulta
	# de Active Record (LIMIT/OFFSET en SQL, no en memoria).
	def index
		pokemons = ::Pokemons::SearchByUser.execute(user_id: current_user.id)
			.in_storage
			.order(:num_pokedex, :id)
			.page(params[:page])
			.per(params[:per_page])

		@pokemons = Pokemons::PokemonDecorator.decorate_collection(pokemons)
		@party_size = ::Pokemons::SearchByUser.execute(user_id: current_user.id).in_party.count
	end

	# El equipo: seis huecos, algunos vacíos. Es la otra mitad de "My PC".
	def party
		pokemons = ::Pokemons::SearchByUser.execute(user_id: current_user.id).in_party
		@party = Pokemons::PokemonDecorator.decorate_collection(pokemons)
		@free_slots = Pokemon::PARTY_SIZE - @party.size
	end

	def add_to_party
		pokemon = owned_pokemon
		result = ::Pokemons::AddToParty.execute(pokemon: pokemon)

		if result.error == :party_full
			redirect_to user_pokemon_index_path(user_id: current_user.id),
				alert: "Your party is full. Send someone to the PC first.", status: :see_other
		else
			redirect_to party_user_pokemon_index_path(user_id: current_user.id),
				notice: "#{pokemon.nickname} joined your party.", status: :see_other
		end
	end

	def send_to_pc
		pokemon = owned_pokemon
		::Pokemons::SendToPc.execute(pokemon: pokemon)

		redirect_to party_user_pokemon_index_path(user_id: current_user.id),
			notice: "#{pokemon.nickname} was sent to your PC.", status: :see_other
	end

	def show
		pokemon = owned_pokemon

		@pokemon = Pokemons::PokemonDecorator.decorate(pokemon)
		@matchups = ::Pokemons::TypeMatchup.execute(type_slugs: @pokemon.type_slugs).value
	end

	def liberate_pokemon
		# `owned_pokemon` primero: `Pokemons::Liberate` resuelve el id por su
		# cuenta y sin esta comprobación borraba el Pokémon de cualquiera.
		pokemon = owned_pokemon

		# El juego no te deja quedarte sin ninguno, y aquí menos: explorar exige
		# equipo y la Pokédex ya no captura, así que soltar el último dejaba la
		# cuenta sin ninguna forma de seguir jugando.
		if current_user.pokemon.count <= 1
			return redirect_to user_pokemon_path(user_id: current_user.id, id: pokemon.id),
				alert: "That's your last Pokémon! You can't release it.", status: :see_other
		end

		::Pokemons::Liberate.execute(id: pokemon.id)
		redirect_to user_pokemon_index_path(user_id: current_user.id),
			notice: "#{pokemon.nickname} was released. Bye!", status: :see_other
	end

	# La red de seguridad: si por lo que sea la cuenta se quedó sin ningún Pokémon
	# —la PokeAPI estaba caída al registrarse y no se llegó a regalar el inicial—,
	# aquí se elige uno.
	def starter
		if current_user.pokemon.exists?
			return redirect_to user_pokemon_index_path(user_id: current_user.id), status: :see_other
		end

		result = ::Users::GrantStarter.execute(user: current_user, num_pokedex: params[:starter_num_pokedex])

		if result.error
			return redirect_to user_pokemon_index_path(user_id: current_user.id),
				alert: 'We could not reach the PokeAPI. Try again in a few seconds.', status: :see_other
		end

		redirect_to user_pokemon_index_path(user_id: current_user.id),
			notice: "#{result.value.nickname} is ready to go. Head out and explore!", status: :see_other
	end

	def edit_nickname
		pokemon = owned_pokemon
		nickname = params[:pokemon][:nickname]
		@pokemon = Pokemons::UpdateUseCase.execute(pokemon: pokemon, nickname: nickname)
		redirect_to user_pokemon_path(user_id: current_user.id, id: params[:id]), status: :see_other
	end

	def compare_with
		pokemon = owned_pokemon
		@pokemon_api = ::Pokeapi::FindPokemon.execute(id: params[:pokemon][:id]).value

		if @pokemon_api.nil?
			return redirect_to user_pokemon_path(user_id: current_user.id, id: params[:id]),
				alert: 'No Pokémon found with that Pokédex number', status: :see_other
		end

		@stats = Pokemons::ComparePokemonUseCase.execute(pokemon1: pokemon, pokemon_api: @pokemon_api)
		@pokemon = Pokemons::PokemonDecorator.decorate(pokemon)

		# Cuánto daño recibe cada uno: para saber cómo golpea A a B basta con
		# mirar el matchup defensivo de B en el tipo de A.
		@my_matchups = ::Pokemons::TypeMatchup.execute(type_slugs: @pokemon.type_slugs).value
		@their_matchups = ::Pokemons::TypeMatchup.execute(type_slugs: @pokemon_api.type_slugs).value
	end

	private

	# Busca SIEMPRE dentro de los Pokémon del usuario de la sesión.
	#
	# Antes se hacía `Base::Find.execute(klass: Pokemon, id: params[:id])`, que
	# resuelve el id sin mirar de quién es: bastaba conocer un id ajeno para
	# liberar, renombrar o mover el Pokémon de otra persona. `params[:user_id]`
	# tampoco servía de filtro, porque viene de la URL y lo pone quien llama.
	#
	# `find` lanza RecordNotFound, que Rails convierte en un 404: la respuesta
	# correcta, y además no revela si ese id existe para otro usuario.
	def owned_pokemon
		current_user.pokemon.find(params[:id])
	end

end
