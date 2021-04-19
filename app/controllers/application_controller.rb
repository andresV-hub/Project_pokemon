class ApplicationController < ActionController::Base

	include Pundit
	protect_from_forgery

	def after_sign_in_path_for(user)
		root_path
	end

end
