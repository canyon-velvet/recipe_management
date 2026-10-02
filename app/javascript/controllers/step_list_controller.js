import { Controller } from "@hotwired/stimulus"

// Reorders recipe step rows and keeps their visible numbers and hidden position fields in DOM order.
export default class extends Controller {
  static targets = ["step", "number", "position"]

  stepTargetConnected() {
    this.renumber()
  }

  moveUp(event) {
    const step = this.stepFor(event)
    const previous = this.visibleSteps()[this.visibleSteps().indexOf(step) - 1]
    if (previous) previous.before(step)
    this.renumber()
  }

  moveDown(event) {
    const step = this.stepFor(event)
    const next = this.visibleSteps()[this.visibleSteps().indexOf(step) + 1]
    if (next) next.after(step)
    this.renumber()
  }

  renumber() {
    this.visibleSteps().forEach((step, index) => {
      step.querySelector("[data-step-list-target='number']").textContent = index + 1
      step.querySelector("[data-step-list-target='position']").value = index + 1
    })
  }

  stepFor(event) {
    return event.currentTarget.closest("[data-step-list-target='step']")
  }

  visibleSteps() {
    return this.stepTargets.filter(step => !step.classList.contains("hidden"))
  }
}
