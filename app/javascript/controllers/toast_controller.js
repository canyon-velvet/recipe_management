import { Controller } from "@hotwired/stimulus"

// A short notice in the corner (e.g. "葱油饼 is ready to review") that goes away by itself.
export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.dismiss(), 8000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.remove()
  }
}
