# El Centro Pokémon: cura a todo el equipo, gratis.
#
# Gratis y no de pago, como en los juegos. La duda al diseñarlo era que sin coste
# el dinero perdería sentido, pero es al revés: las pociones no compiten con el
# Centro porque sirven **a mitad de combate**, que es justo cuando no puedes ir a
# uno. Lo que le da valor al dinero es que perder cuesta, no que curar cueste.
class PokemonCenterController < ApplicationController

	def show
		@party = decorated(current_user.pokemon.in_party)
		@stored_hurt = decorated(current_user.pokemon.in_storage.where('damage > 0'))
		@needs_healing = current_user.pokemon.where('damage > 0').exists?
	end

	def heal
		healed = ::Pokemons::HealAll.execute(user: current_user).value

		notice = if healed.zero?
			'Your Pokémon are already in perfect health.'
		else
			"Your Pokémon are fighting fit! #{healed} #{'Pokémon'.pluralize(healed)} restored."
		end

		redirect_to user_pokemon_center_path(user_id: current_user.id), notice: notice, status: :see_other
	end

	private

	def decorated(scope)
		::Pokemons::PokemonDecorator.decorate_collection(scope)
	end

end
