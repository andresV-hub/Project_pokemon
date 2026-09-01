class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # `dependent: :destroy` en ambas: los avistamientos tienen clave foránea, así
  # que sin esto la base de datos rechaza borrar un usuario —y con él la acción
  # de cerrar la cuenta—; los pokémon no la tienen, pero sin la opción quedarían
  # huérfanos en la tabla.
  has_many :pokemon, dependent: :destroy
  has_many :pokedex_sightings, dependent: :destroy

  after_create :assign_default_role 

  def assign_default_role
  	self.add_role(:user) if self.roles.blank?
  end

end
