import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = {
    format: String,
    url: String
  }

  export(event) {
    event.preventDefault()
    const button = event.currentTarget
    const originalText = button.innerHTML
    
    button.disabled = true
    button.innerHTML = `
      <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-gray-700" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Exporting...
    `

    window.location.href = this.urlValue
    
    // Reset button state after a short delay
    setTimeout(() => {
      button.disabled = false
      button.innerHTML = originalText
    }, 1000)
  }
}
