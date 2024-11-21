import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  handleResponse(event) {
    if (event.detail.success) {
      this.inputTarget.value = ""
    }
  }
} 