# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

role_admin = Role.find_or_create_by({name: :admin})

Role.find_or_create_by({name: :user})

user = User.find_by(email: "andres@andres.es" )
if user.nil? 
 User.create(
 	email: "andres@andres.es",
 	password: Rails.application.credentials.dig(Rails.env.to_sym, :admin, :password),
 	roles: [role_admin])
end