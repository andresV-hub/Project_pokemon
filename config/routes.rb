Rails.application.routes.draw do

	root to: 'pokedex#information'

	devise_for :users, path_names: { sign_in: 'login', sign_out: 'logout' }

	# Endpoint de salud que usa Rails 8 (y config.silence_healthcheck_path).
	get 'up' => 'rails/health#show', as: :rails_health_check

	# API JSON. Todas las colecciones aceptan ?page= y ?per_page= y devuelven los
	# metadatos de paginación en el bloque `meta`.
	namespace :api do
		namespace :v1 do
			resources :pokemons, only: [:index, :show]
			resources :pokedex, only: [:index, :show]
		end
	end

	# `only: []` porque este recurso sólo existe para anidar lo de dentro: no tiene
	# páginas propias. Su `show` era una ruta viva que pedía las 151 especies a la
	# PokeAPI, tiraba el resultado y renderizaba una vista vacía.
	resources :user, only: [] do
		# Encuentros salvajes: la única puerta a los Pokémon que aún no tienes.
		get 'shop', to: 'shop#show', as: :shop
		post 'shop/buy', to: 'shop#buy', as: :shop_buy

		# El Centro Pokémon, gratis como en el juego. La cura es un POST porque
		# cambia el estado del equipo, y tiene su propia página porque es donde se
		# ve de un vistazo cómo está todo el mundo.
		get 'center', to: 'pokemon_center#show', as: :pokemon_center
		post 'center/heal', to: 'pokemon_center#heal', as: :pokemon_center_heal

		get 'explore', to: 'encounters#new', as: :explore
		get 'encounter', to: 'encounters#show', as: :encounter
		post 'encounter/start', to: 'encounters#create', as: :encounter_start
		post 'encounter/trainer', to: 'encounters#create_trainer', as: :encounter_trainer
		post 'encounter/attack', to: 'encounters#attack', as: :encounter_attack
		post 'encounter/catch', to: 'encounters#catch', as: :encounter_catch
		post 'encounter/item', to: 'encounters#item', as: :encounter_item
		post 'encounter/flee', to: 'encounters#flee', as: :encounter_flee

		resources :pokemon, only: [:show, :index] do
			collection do
				get :party
				# Un entrenador sin ningún Pokémon no tiene forma de conseguir uno:
				# explorar exige equipo y la Pokédex ya no captura. Esta es la
				# salida, y sólo funciona cuando de verdad no queda ninguno.
				post :starter
			end

			member do
				patch :liberate_pokemon
				patch :edit_nickname
				patch :compare_with
				patch :add_to_party
				patch :send_to_pc
			end
		end

		resources :pokedex, only: [:show, :index] do
			collection do
				get :information
				# La captura son dos pasos: primero la tirada, y sólo si sale bien
				# se pide el apodo y se guarda.
				post :attempt_capture
				post :add_pokemon_to_team
			end
		end
	end

end
