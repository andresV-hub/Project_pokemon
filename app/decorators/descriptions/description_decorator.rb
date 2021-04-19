module Descriptions
  class DescriptionDecorator < ApplicationDecorator
    

  	def description
  		desc = model['flavor_text_entries'][0]['flavor_text'].gsub("\f"," ")
      desc.gsub("\n"," ")
    end

    def habitat
    	model['habitat']['name'].capitalize
    end

    def base_happiness
    	model['base_happiness']
    end

    def capture_rate
    	(model['capture_rate']*100)/255#Formula propia de pokemon,sin calculos sobre lvl,HP,etc
    end

  end
end