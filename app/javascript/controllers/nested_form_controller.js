import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container"]

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(
      /NEW_RECORD/g,
      new Date().getTime().toString()
    )
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    const row = event.currentTarget.closest("[data-nested-form-row]")
    const destroyField = row.querySelector("input[name*='_destroy']")

    if (destroyField) {
      destroyField.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
  }
}
