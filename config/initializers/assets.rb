# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# `app/assets/javascripts/` es un resto de la época de Sprockets (Rails 5): sus
# ficheros son manifiestos con directivas `//= require`, no módulos ES. El
# problema es que contiene un `application.js` que colisiona con el punto de
# entrada real de importmap (`app/javascript/application.js`): Propshaft resolvía
# el nombre contra el manifiesto viejo, así que `<script type="module">import
# "application"</script>` cargaba un fichero que para un módulo ES es sólo
# comentarios. No fallaba —no hay error en consola— pero dejaba la aplicación sin
# Turbo, sin Stimulus y sin Bootstrap, y con ello sin modales.
Rails.application.config.assets.excluded_paths << Rails.root.join("app/assets/javascripts")
