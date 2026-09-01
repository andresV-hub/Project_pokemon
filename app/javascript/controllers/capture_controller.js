import { Controller } from "@hotwired/stimulus"

// Orquesta la captura en dos pasos (styles.md §6.20): tirada y, sólo si sale
// bien, apodo. Sustituye al script en línea que tenía la vista, que pedía el
// apodo de entrada y daba la captura por hecha.
export default class extends Controller {
  static targets = ["ball", "message", "attempts", "nicknameStep", "retry", "save"]
  static values = {
    attemptUrl: String,
    pokemonId: Number,
    name: String,
    maxAttempts: { type: Number, default: 3 }
  }

  connect() {
    // La tirada empieza sola al abrirse el modal: el usuario ya ha expresado su
    // intención al pulsar "Catch", pedirle un segundo clic sobra.
    this.onShown = () => this.throwBall()
    this.element.addEventListener("shown.bs.modal", this.onShown)
    this.attemptsLeft = this.maxAttemptsValue
  }

  disconnect() {
    this.element.removeEventListener("shown.bs.modal", this.onShown)
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  async throwBall() {
    if (this.attemptsLeft <= 0) return

    this.attemptsLeft -= 1
    this.retryTarget.hidden = true
    this.messageTarget.textContent = `You throw a Poké Ball at ${this.nameValue}…`
    this.attemptsTarget.textContent = ""

    // La animación y la petición corren a la vez: así el resultado no se hace
    // esperar más de lo que dura el gesto.
    this.ballTarget.classList.remove("dex-ball--caught", "dex-ball--escaped")
    if (!this.reducedMotion) this.ballTarget.classList.add("dex-ball--throwing")

    const [result] = await Promise.all([this.requestAttempt(), this.wait(this.reducedMotion ? 0 : 1900)])

    this.ballTarget.classList.remove("dex-ball--throwing")
    if (!result) return this.showError()

    result.caught ? this.showCaught(result) : this.showEscaped()
  }

  async requestAttempt() {
    try {
      const response = await fetch(this.attemptUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content
        },
        body: JSON.stringify({ pokemon_id: this.pokemonIdValue })
      })
      if (!response.ok) return null
      return await response.json()
    } catch {
      return null
    }
  }

  showCaught(result) {
    this.ballTarget.classList.add("dex-ball--caught")
    this.messageTarget.textContent = `Gotcha! ${result.name} was caught!`
    this.attemptsTarget.textContent = ""
    this.nicknameStepTarget.hidden = false
    this.saveTarget.hidden = false
    this.retryTarget.hidden = true
    this.element.querySelector("#nickname-pokemon-field")?.focus()
  }

  showEscaped() {
    this.ballTarget.classList.add("dex-ball--escaped")
    this.messageTarget.textContent = `Oh no! ${this.nameValue} broke free!`

    if (this.attemptsLeft > 0) {
      const balls = this.attemptsLeft === 1 ? "1 Poké Ball" : `${this.attemptsLeft} Poké Balls`
      this.attemptsTarget.textContent = `You have ${balls} left.`
      this.retryTarget.hidden = false
    } else {
      this.attemptsTarget.textContent = `${this.nameValue} got away. Come back to try again.`
      this.retryTarget.hidden = true
    }
  }

  showError() {
    this.messageTarget.textContent = "We could not reach the PokeAPI. Try again in a few seconds."
    this.attemptsTarget.textContent = ""
    this.retryTarget.hidden = false
  }

  save() {
    this.element.querySelector("#form-catch-pokemon")?.requestSubmit()
  }

  wait(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }
}
