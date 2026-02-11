import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async togglePantry(event) {
    const checkbox = event.currentTarget
    const url = checkbox.dataset.groceryListUrlParam
    const inPantry = checkbox.dataset.groceryListPantryParam

    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: new URLSearchParams({ in_pantry: inPantry })
      })

      if (response.ok) {
        const html = response.headers.get("content-type")?.includes("turbo-stream")
          ? await response.text()
          : null

        if (html) {
          const template = document.createElement("template")
          template.innerHTML = html
          template.content.querySelectorAll("turbo-stream").forEach(stream => {
            const action = stream.getAttribute("action")
            const targetId = stream.getAttribute("target")
            const target = document.getElementById(targetId)
            const content = stream.querySelector("template")?.content.cloneNode(true)

            if (action === "remove" && target) {
              target.remove()
            } else if (action === "append" && target && content) {
              target.appendChild(content)
            } else if (action === "update" && target && content) {
              target.replaceChildren(...content.childNodes)
            }
          })

          this.cleanupEmptyGroups()
          this.togglePantrySection()
        }
      }
    } catch (error) {
      console.error("Failed to toggle pantry:", error)
      checkbox.checked = !checkbox.checked
    }
  }

  cleanupEmptyGroups() {
    document.querySelectorAll(".grocery-store-card").forEach(card => {
      // Remove category headers with no items following them
      card.querySelectorAll(".grocery-category-header").forEach(header => {
        let hasItems = false
        let sibling = header.nextElementSibling
        while (sibling && !sibling.classList.contains("grocery-category-header")) {
          if (sibling.classList.contains("grocery-item")) { hasItems = true; break }
          sibling = sibling.nextElementSibling
        }
        if (!hasItems) header.remove()
      })

      // Remove entire store card if no items remain
      if (!card.querySelector(".grocery-item")) card.remove()
    })
  }

  togglePantrySection() {
    const pantryContainer = document.getElementById("pantry_items")
    if (pantryContainer) {
      const hasItems = pantryContainer.querySelector(".grocery-item")
      pantryContainer.closest("div.mt-8")?.classList.toggle("hidden", !hasItems)
    }
  }
}
