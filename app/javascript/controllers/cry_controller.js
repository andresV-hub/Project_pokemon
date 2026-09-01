import { Controller } from "@hotwired/stimulus"

// Reproduce el sonido del Pokémon (styles.md §6.19).
//
// Siempre a petición del usuario: nunca en la carga de la página. Además de ser
// intrusivo, los navegadores bloquean el audio automático y el botón acabaría
// pareciendo roto.
export default class extends Controller {
  static values = { url: String }

  play() {
    if (!this.urlValue) return

    this.audio ||= new Audio(this.urlValue)
    this.audio.volume = 0.4
    this.audio.currentTime = 0
    // Si el navegador rechaza la reproducción no hay nada que hacer ni que
    // avisar: el usuario simplemente no oye nada.
    this.audio.play().catch(() => {})
  }
}
