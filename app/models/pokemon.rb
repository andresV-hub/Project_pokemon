class Pokemon < ApplicationRecord

	belongs_to :user

	# Huecos del equipo. Seis, como en el juego: la gracia está en tener que
	# elegir a quién llevas.
	PARTY_SIZE = 6
	PARTY_SLOTS = (1..PARTY_SIZE).freeze

	validates :nickname, presence: true
	validates :party_position, inclusion: { in: PARTY_SLOTS },
	                           uniqueness: { scope: :user_id },
	                           allow_nil: true

	# `party_position` nulo significa "guardado en el PC".
	scope :in_party, -> { where.not(party_position: nil).order(:party_position) }
	scope :in_storage, -> { where(party_position: nil) }

	def in_party?
		party_position.present?
	end

	# Los movimientos que sabe, en orden de aprendizaje. Son la **única** fuente:
	# el combate ya no los recalcula por nivel, porque tener dos listas hacía que la
	# ficha enseñara un repertorio y el combate usara otro.
	def move_names
		[atack0, atack1, atack2, atack3].compact_blank
	end

	# --- Vida ---------------------------------------------------------------
	#
	# La vida máxima no está guardada: se deriva de la estadística base y del
	# nivel, igual que en el combate. Guardarla sería un dato que habría que
	# recalcular cada vez que se sube de nivel o se evoluciona.

	def max_hp
		::Pokemons::LevelStats.hp(hp, level)
	end

	# Lo que le queda. `damage` puede quedarse por encima del máximo si el máximo
	# baja —evolucionar a una forma con menos HP no pasa en gen 1, pero el `max`
	# lo cubre igual—, y nunca devuelve un número negativo.
	def current_hp
		[max_hp - damage.to_i, 0].max
	end

	def fainted?
		current_hp.zero?
	end

	def full_health?
		damage.to_i.zero?
	end

	# Cura una cantidad, o hasta arriba si no se dice cuánta. Devuelve lo que ha
	# recuperado de verdad, que es lo que hay que contar: «recuperó 20 PS» cuando
	# sólo le faltaban 5 sería mentira, y además significa que la poción se
	# desperdició.
	def heal!(amount = nil)
		before = current_hp
		self.damage = amount.nil? ? 0 : [damage.to_i - amount.to_i, 0].max
		save!

		current_hp - before
	end

	def take_damage!(amount)
		self.damage = [damage.to_i + amount.to_i, max_hp].min
		save!
	end

end
