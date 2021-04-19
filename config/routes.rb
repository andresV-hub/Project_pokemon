Rails.application.routes.draw do

	root to: 'pokedex#information'

	devise_for :users, path_names:{sign_in: 'login',sign_out: 'logout'}

	

	resources :user do
    	resources :pokemon, only: [:show,:index] do
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
