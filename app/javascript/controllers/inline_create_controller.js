import { Controller } from "@hotwired/stimulus"

// Reusable controller for inline-create modals (ingredients, sources, etc.)
// Collects all named inputs inside the dialog and POSTs as FormData.
export default class extends Controller {
  static targets = ["dialog", "errors", "prefill"]
  static values = { createUrl: String }

  openModal(event) {
    this.triggerAutocomplete = event.target.closest("[data-controller*='autocomplete']")
    if (this.hasPrefillTarget) {
      this.prefillTarget.value = event.detail.query || ""
    }
    this.errorsTarget.textContent = ""
    this.dialogTarget.showModal()
  }

  closeModal() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) {
      this.closeModal()
    }
  }

  async save(event) {
    event.preventDefault()

    try {
      const formData = new FormData()
      this.dialogTarget.querySelectorAll("input[name], select[name], textarea[name]").forEach(el => {
        if (el.type === "checkbox") {
          if (el.checked) formData.append(el.name, el.value)
        } else {
          formData.append(el.name, el.value)
        }
      })

      const response = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: formData
      })

      if (response.ok) {
        const data = await response.json()
        const autocompleteCtrl = this.application.getControllerForElementAndIdentifier(
          this.triggerAutocomplete, "autocomplete"
        )
        if (autocompleteCtrl) {
          autocompleteCtrl.setSelection(data.id, data.name)
        }
        this.closeModal()
        this.resetForm()
      } else {
        const data = await response.json()
        this.errorsTarget.textContent = data.errors ? data.errors.join(", ") : "保存失败"
      }
    } catch (error) {
      console.error("Inline create error:", error)
      this.errorsTarget.textContent = "保存失败，请重试"
    }
  }

  resetForm() {
    this.dialogTarget.querySelectorAll("input[name], select[name], textarea[name]").forEach(el => {
      if (el.type === "checkbox") {
        el.checked = false
      } else if (el.tagName === "SELECT") {
        el.selectedIndex = 0
      } else {
        el.value = ""
      }
    })
  }
}
