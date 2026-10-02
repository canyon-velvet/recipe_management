import { Controller } from "@hotwired/stimulus"

// Summarises the checked tag checkboxes in the closed dropdown, like a native select's current value.
export default class extends Controller {
  static targets = ["checkbox", "name", "summary"]
  static values = { placeholder: String }

  connect() {
    this.render()
  }

  render() {
    const names = this.checkboxTargets
      .map((checkbox, index) => checkbox.checked && this.nameTargets[index].textContent)
      .filter(Boolean)

    this.summaryTarget.textContent = names.length > 0 ? names.join(", ") : this.placeholderValue
    this.summaryTarget.classList.toggle("text-gray-400", names.length === 0)
  }
}
