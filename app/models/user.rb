class User < ApplicationRecord
  rolify

  # Los tres iniciales de la primera generación.
  STARTERS = { 1 => 'Bulbasaur', 4 => 'Charmander', 7 => 'Squirtle' }.freeze

  # Elección del formulario de registro; no es una columna.
  attr_accessor :starter_num_pokedex
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
  after_create :grant_starter

  def assign_default_role
  	self.add_role(:user) if self.roles.blank?
  end

  private

  # El inicial se concede aquí, pero **sin poder tumbar el registro**: depende de
  # la PokeAPI, y si estuviera caída una excepción revertiría la transacción y la
  # cuenta no llegaría a crearse. Si falla, el usuario existe y se queda sin
  # inicial; es un mal menor frente a no poder registrarse.
  def grant_starter
    ::Users::GrantStarter.execute(user: self, num_pokedex: starter_num_pokedex)
  rescue StandardError => e
    Rails.logger.error("[GrantStarter] #{e.class}: #{e.message} (user #{id})")
  end

end
