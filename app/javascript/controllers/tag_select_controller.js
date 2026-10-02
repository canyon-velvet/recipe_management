import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// Turns a <select multiple> into a searchable tag picker with removable pills.
export default class extends Controller {
  static values = { noResults: String, removeLabel: String }

  connect() {
    this.tomSelect = new TomSelect(this.element, {
      plugins: { remove_button: { title: this.removeLabelValue } },
      create: false,
      persist: false,
      maxOptions: null,
      render: { no_results: () => this.noResultsElement() }
    })
  }

  disconnect() {
    this.tomSelect?.destroy()
  }

  noResultsElement() {
    const div = document.createElement("div")
    div.className = "no-results"
    div.textContent = this.noResultsValue
    return div
  }
}
