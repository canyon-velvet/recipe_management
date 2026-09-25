import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

export default class extends Controller {
  static targets = ["input", "preview", "writeTab", "previewTab"]
  static values = { emptyText: String }

  connect() {
    this.showWrite()
  }

  showWrite() {
    this.inputTarget.classList.remove("hidden")
    this.previewTarget.classList.add("hidden")
    this.writeTabTarget.classList.add("tab-active")
    this.previewTabTarget.classList.remove("tab-active")
  }

  showPreview() {
    const text = this.inputTarget.value
    if (text.trim() === "") {
      const empty = document.createElement("p")
      empty.className = "text-gray-400 text-sm"
      empty.textContent = this.emptyTextValue
      this.previewTarget.replaceChildren(empty)
    } else {
      this.previewTarget.innerHTML = marked(text, { breaks: true, gfm: true })
    }
    this.inputTarget.classList.add("hidden")
    this.previewTarget.classList.remove("hidden")
    this.previewTabTarget.classList.add("tab-active")
    this.writeTabTarget.classList.remove("tab-active")
  }
}
