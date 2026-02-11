import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "input", "results", "slotId"]
  static values = { searchUrl: String }

  connect() {
    this.timeout = null
  }

  openForSlot(event) {
    const slotId = event.currentTarget.dataset.mealSlotId
    this.slotIdTarget.value = slotId
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = '<li class="text-sm text-gray-400 text-center py-4">输入关键词搜索</li>'
    this.dialogTarget.showModal()
    this.inputTarget.focus()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }

  onInput() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()

    if (query.length === 0) {
      this.resultsTarget.innerHTML = '<li class="text-sm text-gray-400 text-center py-4">输入关键词搜索</li>'
      return
    }

    this.timeout = setTimeout(() => this.fetchResults(query), 250)
  }

  async fetchResults(query) {
    const url = `${this.searchUrlValue}?q=${encodeURIComponent(query)}`
    const response = await fetch(url, {
      headers: { "Accept": "application/json" }
    })
    const recipes = await response.json()
    this.renderResults(recipes)
  }

  renderResults(recipes) {
    if (recipes.length === 0) {
      this.resultsTarget.innerHTML = '<li class="text-sm text-gray-400 text-center py-4">没有找到菜谱</li>'
      return
    }

    this.resultsTarget.innerHTML = recipes.map(r => `
      <li class="flex items-center justify-between px-3 py-2 rounded-lg cursor-pointer hover:bg-indigo-50 transition-colors"
          data-action="click->recipe-select#select"
          data-recipe-id="${r.id}">
        <span class="text-sm text-gray-800">${r.name}</span>
        <span class="text-xs text-gray-400">${r.category || ""}</span>
      </li>
    `).join("")
  }

  async select(event) {
    const recipeId = event.currentTarget.dataset.recipeId
    const slotId = this.slotIdTarget.value
    const url = `/meal_slots/${slotId}/meal_slot_recipes`

    try {
      const response = await this.turboFetch(url, "POST", {
        "meal_slot_recipe[recipe_id]": recipeId
      })
      if (response.ok) {
        this.applyTurboStream(await response.text())
        this.close()
      }
    } catch (error) {
      console.error("Failed to add recipe:", error)
    }
  }

  async toggleGrocery(event) {
    const checkbox = event.currentTarget
    const url = checkbox.dataset.url

    try {
      const response = await this.turboFetch(url, "PATCH", {
        "meal_slot_recipe[add_to_grocery_list]": checkbox.checked
      })
      if (response.ok) {
        this.applyTurboStream(await response.text())
      }
    } catch (error) {
      console.error("Failed to toggle grocery:", error)
    }
  }

  // Helpers

  turboFetch(url, method, params) {
    const formData = new FormData()
    Object.entries(params).forEach(([k, v]) => formData.append(k, v))

    return fetch(url, {
      method,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: formData
    })
  }

  applyTurboStream(html) {
    const template = document.createElement("template")
    template.innerHTML = html
    template.content.querySelectorAll("turbo-stream").forEach(stream => {
      document.querySelector(`#${stream.getAttribute("target")}`)
        ?.replaceChildren(...stream.querySelector("template").content.cloneNode(true).childNodes)
    })
  }
}
