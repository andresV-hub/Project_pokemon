# Cuántas unidades de un objeto tiene un usuario.
class InventoryItem < ApplicationRecord

  belongs_to :user

  validates :kind, presence: true,
                   inclusion: { in: ->(_) { ::Shop::Catalog.kinds } },
                   uniqueness: { scope: :user_id }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :available, -> { where(quantity: 1..) }

  def name = ::Shop::Catalog.name(kind)

  def multiplier = ::Shop::Catalog.multiplier(kind)

end
