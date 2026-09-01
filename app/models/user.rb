class User < ApplicationRecord
  rolify

  # Iniciales a elegir. Además de los tres clásicos, Pikachu y Eevee: son las dos
  # caras de Pokémon Amarillo y las especies más reconocibles de la generación.
  #
  # El tipo va en la propia constante porque la vista lo necesita para el tinte, y
  # deducirlo por el orden sólo funcionaba mientras fueran tres.
  STARTERS = {
    1 => { name: 'Bulbasaur', type: 'grass' },
    4 => { name: 'Charmander', type: 'fire' },
    7 => { name: 'Squirtle', type: 'water' },
    25 => { name: 'Pikachu', type: 'electric' },
    133 => { name: 'Eevee', type: 'normal' }
  }.freeze

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
