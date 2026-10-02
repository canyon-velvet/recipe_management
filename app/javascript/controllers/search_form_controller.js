import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "query", "tag"]

  submitLater() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.formTarget.requestSubmit(), 350)
  }

  clearAll() {
    this.queryTarget.value = ""
    this.tagTarget.value = ""
    this.formTarget.requestSubmit()
  }
}
