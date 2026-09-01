import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configuración de Stimulus
application.debug = false
window.Stimulus = application

export { application }
