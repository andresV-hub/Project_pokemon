import { Controller } from "@hotwired/stimulus"

// Despliegue del menú de navegación en móvil (styles.md §8): por debajo de
// 768px los enlaces no caben en una fila y se muestran apilados.
export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    const open = this.menuTarget.classList.toggle("is-open")
    event.currentTarget.setAttribute("aria-expanded", String(open))
    event.currentTarget.setAttribute("aria-label", open ? "Cerrar el menú" : "Abrir el menú")
  }
}
