# Tabla del caché de Solid Cache.
#
# Va en la base de datos principal y no en una aparte, que es lo que hace Rails 8
# por defecto: este proyecto tiene una sola base y añadir una segunda sólo para
# esto complicaría el despliegue sin resolver nada.
#
# Lo que se guarda aquí son respuestas de la PokeAPI —inmutables y con caducidad
# de 30 días—, así que la tabla crece poco y Solid Cache la poda sola cuando
# supera su tamaño máximo.
class CreateSolidCacheEntries < ActiveRecord::Migration[8.1]

  def change
    create_table :solid_cache_entries do |t|
      t.binary :key, null: false, limit: 1024
      t.binary :value, null: false, limit: 536_870_912
      t.datetime :created_at, null: false
      t.integer :key_hash, null: false, limit: 8
      t.integer :byte_size, null: false, limit: 4
    end

    add_index :solid_cache_entries, :key_hash, unique: true
    add_index :solid_cache_entries, %i[key_hash byte_size]
    add_index :solid_cache_entries, :byte_size
  end

end
