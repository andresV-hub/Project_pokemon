// Punto de entrada gestionado por importmap-rails.
import "@hotwired/turbo-rails"
import "controllers"
import * as bootstrap from "bootstrap"

// Los scripts en línea de las vistas usan la API de Bootstrap 5 para abrir y
// cerrar modales, así que la exponemos en el ámbito global.
window.bootstrap = bootstrap
