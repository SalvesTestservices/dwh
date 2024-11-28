import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["metricSelect", "stepContainer", "nextStep", "timeperiodSelect", "submitButton"]

  connect() {
    if (this.hasSubmitButtonTarget) {
      this.validateForm()
    }
  }

  metricSelected(event) {
    const metric = event.target.value
    if (!metric) return

    fetch(`/dataview/metric_config?metric=${metric}`, {
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
    })
  }

  timeperiodSelected() {
    this.validateForm()
  }

  validateForm() {
    if (!this.hasSubmitButtonTarget) return

    const metric = this.metricSelectTarget.value
    const timePeriod = this.hasTimeperiodSelectTarget ? this.timeperiodSelectTarget.value : null
    const submitButton = this.submitButtonTarget

    if (metric && (!this.hasTimeperiodSelectTarget || timePeriod)) {
      submitButton.disabled = false
      submitButton.classList.remove('opacity-50', 'cursor-not-allowed')
      submitButton.classList.add('hover:bg-blue-700')
    } else {
      submitButton.disabled = true
      submitButton.classList.add('opacity-50', 'cursor-not-allowed')
      submitButton.classList.remove('hover:bg-blue-700')
    }
  }
}
