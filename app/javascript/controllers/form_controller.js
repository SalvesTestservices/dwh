import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton", "loading", "timeperiodError", "groupError", "categoryError"]

  connect() {
    this.validate()
  }

  validate() {
    const form = this.element.querySelector('form')
    const isValid = form.checkValidity()
    
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !isValid
      this.submitButtonTarget.classList.toggle('opacity-50', !isValid)
      this.submitButtonTarget.classList.toggle('cursor-not-allowed', !isValid)
    }
    
    // Show/hide error messages
    if (this.hasTimeperiodErrorTarget) {
      this.toggleErrorMessage('timeperiod')
    }
    if (this.hasGroupErrorTarget) {
      this.toggleErrorMessage('group')
    }
    if (this.hasCategoryErrorTarget) {
      this.toggleErrorMessage('category')
    }
  }

  toggleErrorMessage(fieldName) {
    const input = this.element.querySelector(`[name="${fieldName}"]`)
    const errorTarget = this[`${fieldName}ErrorTarget`]
    
    if (input && errorTarget) {
      errorTarget.classList.toggle('hidden', input.value !== '')
    }
  }

  submit(event) {
    event.preventDefault()
    const form = event.target

    // Show loading state
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
    
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
    }

    fetch(form.action, {
      method: form.method,
      body: new FormData(form),
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    }).then(response => {
      if (response.ok) {
        return response.text()
      }
      throw new Error('Network response was not ok')
    }).then(html => {
      Turbo.renderStreamMessage(html)
    }).finally(() => {
      // Hide loading state
      if (this.hasLoadingTarget) {
        this.loadingTarget.classList.add('hidden')
      }
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = false
      }
    })
  }
}
