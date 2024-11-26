import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  static values = {
    loadingHtml: String
  }

  connect() {
    // ... existing code if any ...
  }

  // Add before form submission
  handleSubmit(event) {
    const chatsContainer = document.getElementById("chats")
    chatsContainer.insertAdjacentHTML("beforeend", this.element.dataset.chatLoadingHtml)
  }

  // After response received
  handleResponse(event) {
    const loadingElement = document.getElementById("chat-loading")
    if (loadingElement) {
      loadingElement.remove()
    }
    this.inputTarget.value = ""
  }
} 