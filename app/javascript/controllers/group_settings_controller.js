import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["groupOption"]

  connect() {
    this.updateGroupSettings()
  }

  toggleGrouping(event) {
    this.updateGroupSettings()
  }

  updateGroupSettings() {
    const groupSettings = {}
    
    this.groupOptionTargets.forEach(checkbox => {
      if (checkbox.checked) {
        groupSettings[checkbox.value] = true
      }
    })

    this.saveGroupSettings(groupSettings)
  }

  async saveGroupSettings(groupSettings) {
    const reportId = this.element.dataset.reportId
    const csrfToken = document.querySelector("meta[name='csrf-token']").content

    try {
      const response = await fetch(`/datalab/designer/${reportId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          column_config: {
            ...this.currentColumnConfig,
            group_by: groupSettings
          }
        })
      })

      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
    } catch (error) {
      console.error('Error saving group settings:', error)
    }
  }

  get currentColumnConfig() {
    const configElement = document.getElementById('current-column-config')
    return configElement ? JSON.parse(configElement.dataset.config) : {}
  }
} 