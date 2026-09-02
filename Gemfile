source 'https://rubygems.org'

ruby '>= 3.2.0'

gem 'rails', '~> 8.1.3'

# Base de datos
gem 'mysql2', '~> 0.5'

# Servidor de aplicaciones
gem 'puma', '~> 8.0'

# Asset pipeline (Rails 8: Propshaft + importmap + cssbundling)
gem 'propshaft', '~> 1.3'
gem 'importmap-rails', '~> 2.2'
gem 'cssbundling-rails', '~> 1.4'
gem 'turbo-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.3'

# APIs JSON
gem 'jbuilder', '~> 2.15'

# Reduce el tiempo de arranque cacheando operaciones costosas; requerido en config/boot.rb
gem 'bootsnap', '>= 1.18', require: false

# Cliente HTTP para consumir la PokeAPI
gem 'rest-client', '~> 2.1'

# Configuración por entorno (config/settings*.yml)
gem 'config', '~> 5.6'

# Autenticación, roles y autorización
gem 'devise', '~> 5.0'
gem 'rolify', '~> 6.0'

# Paginación
gem 'kaminari', '~> 1.2'

# Decoradores de vista
gem 'draper', '~> 4.0'

# Zonas horarias en Windows/JRuby
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'byebug', platforms: %i[mri windows]
  gem 'debug', require: 'debug/prelude'
end

group :development do
  gem 'web-console'
  gem 'listen', '~> 3.9'
end

group :test do
  gem 'capybara', '>= 3.39'
  gem 'selenium-webdriver', '>= 4.20'
  gem 'sqlite3', '>= 2.0'
end
