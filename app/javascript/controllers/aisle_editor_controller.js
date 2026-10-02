import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Edit-aisles pop-up. The list itself is a Turbo Frame; this opens and closes the dialog, saves a
// rename when the field changes, and reloads the page on close if anything changed, so the page
// behind shows the new names and order.
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  submit(event) {
    event.target.form.requestSubmit()
  }

  markChanged(event) {
    if (event.detail.success) this.changed = true
  }

  refresh() {
    if (this.changed) Turbo.visit(window.location.href, { action: "replace" })
  }
}
