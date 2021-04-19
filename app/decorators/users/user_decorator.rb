module Users
  class UserDecorator < ApplicationDecorator

    decorates :user
    
    delegate :id, :name, :last_name, :phone, :email, :phone



  end
end