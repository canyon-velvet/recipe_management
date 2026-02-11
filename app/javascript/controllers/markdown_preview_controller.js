import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

export default class extends Controller {
  static targets = ["input", "preview", "writeTab", "previewTab"]

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
      this.previewTarget.innerHTML = '<p class="text-gray-400 text-sm">无内容可预览</p>'
    } else {
      this.previewTarget.innerHTML = marked(text, { breaks: true, gfm: true })
    }
    this.inputTarget.classList.add("hidden")
    this.previewTarget.classList.remove("hidden")
    this.previewTabTarget.classList.add("tab-active")
    this.writeTabTarget.classList.remove("tab-active")
  }
}
