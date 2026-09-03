class ApplicationController < ActionController::Base

	# Todas las vistas usan `current_user`, así que sin sesión hay que mandar al
	# login en lugar de reventar con un nil. Los controladores de Devise quedan
	# fuera para poder iniciar sesión y registrarse.
	before_action :authenticate_user!, unless: :devise_controller?
	before_action :configure_permitted_parameters, if: :devise_controller?

	# Un índice único de la base saltando no debe acabar en un 500.
	#
	# Pasó al desplegar: la primera petición tardó diez segundos —la máquina del
	# plan gratuito estaba despertando—, no se vio respuesta, se volvió a pulsar, y
	# la segunda comprobó que el email estaba libre **antes** de que la primera
	# confirmara su transacción. Las validaciones de unicidad de Rails no protegen
	# de eso: entre el `SELECT` y el `INSERT` hay una ventana, y con diez segundos
	# de latencia es facilísima de abrir con un doble clic.
	#
	# En local no aparece nunca, porque ahí todo responde en milisegundos.
	rescue_from ActiveRecord::RecordNotUnique, with: :handle_duplicate

	def after_sign_in_path_for(user)
		root_path
	end

	protected

	def handle_duplicate(error)
		redirect_back fallback_location: root_path,
			alert: self.class.duplicate_message(error), status: :see_other
	end

	# Separado de la redirección para poder comprobarlo sin montar una petición
	# entera: es una decisión de texto, no de navegación.
	#
	# El único índice único que un visitante puede tocar dos veces seguidas es el del
	# email, así que ese caso lleva un mensaje que dice **qué hacer**; para cualquier
	# otro basta con no reventar.
	def self.duplicate_message(error)
		if error.message.include?('users_on_email')
			'That email address is already registered. Try logging in instead.'
		else
			'That was already saved. Please try again.'
		end
	end

	# Devise sólo acepta email y contraseña salvo que se declaren los demás. Sin
	# esto, los campos `name`, `last_name` y `phone` que el formulario de registro
	# lleva pidiendo desde siempre se descartaban en silencio y se guardaban nulos.
	def configure_permitted_parameters
		extra = %i[name last_name phone]
		devise_parameter_sanitizer.permit(:sign_up, keys: extra + [:starter_num_pokedex])
		devise_parameter_sanitizer.permit(:account_update, keys: extra)
	end

end
