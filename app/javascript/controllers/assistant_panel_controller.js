import { Controller } from "@hotwired/stimulus"

// Opens and closes the assistant side panel, remembers that choice in a cookie (so the next page arrives the same
// way, without a flash), keeps the chat scrolled to the newest message, and sends on Enter.
export default class extends Controller {
  static targets = ["panel", "toggle", "messages", "message", "form", "input"]

  toggle() {
    this.panelTarget.classList.contains("hidden") ? this.open() : this.close()
  }

  open() {
    this.show(true)
    this.scrollToEnd()
    this.inputTarget.focus()
  }

  close() {
    this.show(false)
  }

  // A new message (sent or received) scrolls the chat to it.
  messageTargetConnected() {
    this.scrollToEnd()
  }

  // Enter sends; Shift+Enter is a new line. Enter while an input method is still composing (e.g. Chinese) isn't a send.
  send(event) {
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return

    event.preventDefault()
    if (this.inputTarget.value.trim()) this.formTarget.requestSubmit()
  }

  sent(event) {
    if (event.detail.success) this.formTarget.reset()
  }

  // private

  show(open) {
    this.panelTarget.classList.toggle("hidden", !open)
    document.body.classList.toggle("assistant-open", open)
    this.toggleTargets.forEach(button => button.setAttribute("aria-expanded", open))
    document.cookie = `assistant_open=${open ? 1 : 0}; path=/; max-age=31536000; SameSite=Lax`
  }

  scrollToEnd() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
