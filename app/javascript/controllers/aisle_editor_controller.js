import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Edit-aisles pop-up, available on every page. The list itself is a Turbo Frame; this opens and closes
// the dialog and saves a rename when the field changes. Once the dialog is closed and no save is in
// flight, a page that shows aisles (marked data-reload-on-aisle-change) is reloaded if anything changed;
// any other page keeps its state, e.g. an unsaved recipe form, and only the list is reloaded, so an
// unsaved rename and its error don't come back on reopen.
export default class extends Controller {
  static targets = ["dialog", "frame"]

  connect() {
    this.pending = 0
  }

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

  submitStarted() {
    this.pending++
  }

  // A rename saved on blur can finish after the dialog has already closed.
  submitEnded(event) {
    this.pending--
    if (event.detail.success) this.changed = true
    if (!this.dialogTarget.open) this.refresh()
  }

  refresh() {
    if (this.pending > 0) return

    if (this.changed && document.querySelector("[data-reload-on-aisle-change]")) {
      Turbo.visit(window.location.href, { action: "replace" })
    } else {
      this.frameTarget.reload()
      this.changed = false
    }
  }
}
