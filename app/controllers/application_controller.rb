class ApplicationController < ActionController::Base

	# Todas las vistas usan `current_user`, así que sin sesión hay que mandar al
	# login en lugar de reventar con un nil. Los controladores de Devise quedan
	# fuera para poder iniciar sesión y registrarse.
	before_action :authenticate_user!, unless: :devise_controller?
	before_action :configure_permitted_parameters, if: :devise_controller?

	def after_sign_in_path_for(user)
		root_path
	end

	protected

	# Devise sólo acepta email y contraseña salvo que se declaren los demás. Sin
	# esto, los campos `name`, `last_name` y `phone` que el formulario de registro
	# lleva pidiendo desde siempre se descartaban en silencio y se guardaban nulos.
	def configure_permitted_parameters
		extra = %i[name last_name phone]
		devise_parameter_sanitizer.permit(:sign_up, keys: extra + [:starter_num_pokedex])
		devise_parameter_sanitizer.permit(:account_update, keys: extra)
	end

end
