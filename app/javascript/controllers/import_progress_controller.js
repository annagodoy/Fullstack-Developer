import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.timer = setTimeout(() => this.refresh(), 3000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  refresh() {
    const frame = this.element.closest("turbo-frame")

    if (frame.hasAttribute("src")) {
      frame.reload()
    } else {
      frame.src = this.urlValue
    }
  }
}