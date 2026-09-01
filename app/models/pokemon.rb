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

end
