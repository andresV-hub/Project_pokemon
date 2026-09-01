Config.setup do |config|
  config.const_name = 'Settings'

  # Permite sobrescribir cualquier ajuste desde el entorno, que es como los
  # contenedores de docker compose inyectan los datos de conexión:
  #   SETTINGS__DATABASE__DB_HOST=db
  config.use_env = true
  config.env_prefix = 'SETTINGS'
  config.env_separator = '__'
end
