class ApplicationController < ActionController::Base

	# Pundit 2.x: `include Pundit` fue sustituido por `Pundit::Authorization`.
	include Pundit::Authorization

	# Todas las vistas usan `current_user`, así que sin sesión hay que mandar al
	# login en lugar de reventar con un nil. Los controladores de Devise quedan
	# fuera para poder iniciar sesión y registrarse.
	before_action :authenticate_user!, unless: :devise_controller?

	def after_sign_in_path_for(user)
		root_path
	end

end
