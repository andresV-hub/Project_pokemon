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

	resources :user do
		# Encuentros salvajes: la única puerta a los Pokémon que aún no tienes.
		get 'shop', to: 'shop#show', as: :shop
		post 'shop/buy', to: 'shop#buy', as: :shop_buy

		get 'explore', to: 'encounters#new', as: :explore
		get 'encounter', to: 'encounters#show', as: :encounter
		post 'encounter/start', to: 'encounters#create', as: :encounter_start
		post 'encounter/trainer', to: 'encounters#create_trainer', as: :encounter_trainer
		post 'encounter/attack', to: 'encounters#attack', as: :encounter_attack
		post 'encounter/catch', to: 'encounters#catch', as: :encounter_catch
		post 'encounter/flee', to: 'encounters#flee', as: :encounter_flee

		resources :pokemon, only: [:show, :index] do
			collection do
				get :party
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
