# Draper envuelve las colecciones en su propio decorador, que por defecto no
# expone los métodos que Kaminari necesita para pintar el paginador. Delegarlos
# permite hacer `paginate @pokemons` con la colección ya decorada.
class ApplicationCollectionDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_pages, :limit_value, :total_count, :offset_value,
           :entry_name, :first_page?, :last_page?, :next_page, :prev_page, :out_of_range?
end
