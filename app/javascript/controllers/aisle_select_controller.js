import { Controller } from "@hotwired/stimulus"

// Lets the aisle dropdown create a new aisle inline: choosing "+ New aisle…" reveals a name field.
export default class extends Controller {
  static targets = ["select", "newAisle", "input", "error"]
  static values = { createUrl: String, errorText: String }

  change() {
    if (this.selectTarget.value !== "new") return

    this.selectTarget.value = ""
    this.newAisleTarget.hidden = false
    this.inputTarget.focus()
  }

  cancel() {
    this.inputTarget.value = ""
    this.errorTarget.textContent = ""
    this.newAisleTarget.hidden = true
  }

  async add(event) {
    event.preventDefault()
    const formData = new FormData()
    formData.append("aisle[name]", this.inputTarget.value)

    try {
      const response = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: formData
      })
      const data = await response.json()

      if (response.ok) {
        this.insertOption(data)
        this.cancel()
      } else {
        this.errorTarget.textContent = data.errors ? data.errors.join(", ") : this.errorTextValue
      }
    } catch (error) {
      console.error("Aisle create error:", error)
      this.errorTarget.textContent = this.errorTextValue
    }
  }

  insertOption({ id, name }) {
    const option = document.createElement("option")
    option.value = id
    option.textContent = name
    this.selectTarget.querySelector("option[value='new']").before(option)
    this.selectTarget.value = id
  }
}
