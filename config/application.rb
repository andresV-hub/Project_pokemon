require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ProjectPokemon
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    config.autoload_lib(ignore: %w[assets tasks])

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Propshaft sirve los assets ya compilados desde app/assets/builds
    # (generados por `npm run build:css`) además de images y stylesheets.
    config.assets.excluded_paths << Rails.root.join('app/assets/stylesheets')

    # Las imágenes vienen todas de la PokeAPI por URL y no se sube ninguna, así que
    # Active Storage no genera variantes. Sin esto avisa en cada arranque de que le
    # falta `image_processing`, que sería una gema más que instalar para algo que no
    # se usa.
    config.active_storage.variant_processor = :disabled
  end
end
