class HomeController < ApplicationController

	before_action :authenticate_user!, except: [:index, :show]
	#after_action :verify_authorized
	def initialize(args)
		
	end
	
	
end