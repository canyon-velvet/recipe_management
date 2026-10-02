import { Controller } from "@hotwired/stimulus"

// Shows the checked tag checkboxes as removable chips inside a dropdown-style control.
export default class extends Controller {
  static targets = ["checkbox", "chips", "placeholder"]
  static values = { removeLabel: String }

  connect() {
    this.render()
  }

  render() {
    const checked = this.checkboxTargets.filter(checkbox => checkbox.checked)
    this.chipsTarget.replaceChildren(...checked.map(checkbox => this.buildChip(checkbox)))
    this.placeholderTarget.hidden = checked.length > 0
  }

  remove(event) {
    event.stopPropagation()
    const checkbox = this.checkboxTargets.find(box => box.value === event.currentTarget.dataset.value)
    checkbox.checked = false
    this.render()
  }

  buildChip(checkbox) {
    const name = checkbox.closest("label").querySelector(".tag-option-name").textContent

    const chip = document.createElement("span")
    chip.className = "tag-chip"
    chip.append(name)

    const button = document.createElement("button")
    button.type = "button"
    button.className = "tag-chip-remove"
    button.textContent = "×"
    button.dataset.value = checkbox.value
    button.dataset.action = "tag-select#remove"
    button.setAttribute("aria-label", `${this.removeLabelValue} ${name}`)
    chip.append(button)

    return chip
  }
}
