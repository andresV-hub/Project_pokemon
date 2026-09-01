module Users
  # Regala el Pokémon inicial a una cuenta recién creada.
  #
  # Sin esto, un usuario nuevo no tiene con quién combatir y los encuentros son
  # un callejón sin salida: hace falta al menos un Pokémon para poder pelear.
  class GrantStarter < BaseService

    def initialize(user:, num_pokedex: nil)
      @user = user
      # Sólo los tres iniciales. Si llega cualquier otra cosa —un formulario
      # manipulado pidiendo Mewtwo— se cae al primero de la lista.
      @num_pokedex = User::STARTERS.key?(num_pokedex.to_i) ? num_pokedex.to_i : User::STARTERS.keys.first
    end

    def service_execute
      pokemon = ::Pokeapi::FindPokemon.execute(id: @num_pokedex).value
      description = ::Pokeapi::FindDescription.execute(id: @num_pokedex).value
      return ServiceResult.new(error: :pokeapi_unavailable) if pokemon.nil? || description.nil?

      ::Pokemons::Create.execute(
        pokemon: pokemon,
        user: @user,
        description: description,
        nickname: pokemon.name
      )

      # El inicial va directo al equipo: es el Pokémon con el que se empieza a
      # jugar, no algo que haya que ir a sacar del PC.
      ::Pokemons::AddToParty.execute(pokemon: @user.pokemon.reload.last)

      ServiceResult.new(value: @user.pokemon.last)
    end

  end
end
