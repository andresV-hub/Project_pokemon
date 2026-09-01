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
		resources :pokemon, only: [:show, :index] do
			member do
				patch :liberate_pokemon
				patch :edit_nickname
				patch :compare_with
			end
		end

		resources :pokedex, only: [:show, :index] do
			collection do
				get :information
				post :add_pokemon_to_team
			end
		end
	end

end
