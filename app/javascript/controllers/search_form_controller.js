import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "query", "category"]

  submitLater() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.formTarget.requestSubmit(), 350)
  }

  clearAll() {
    this.queryTarget.value = ""
    this.categoryTarget.value = ""
    this.formTarget.requestSubmit()
  }
}
