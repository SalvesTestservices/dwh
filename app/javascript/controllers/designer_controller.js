import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["availableAttributes", "canvas", "draggable"]

  connect() {
    this.draggableTargets.forEach(draggable => {
      draggable.setAttribute('draggable', true)
      draggable.addEventListener('dragstart', this.dragStart.bind(this))
    })
  }

  dragStart(event) {
    event.dataTransfer.setData('text/plain', event.target.dataset.attribute)
  }

  dragOver(event) {
    event.preventDefault()
    event.currentTarget.classList.add('border-blue-500')
  }

  dragLeave(event) {
    event.currentTarget.classList.remove('border-blue-500')
  }

  async drop(event) {
    event.preventDefault()
    const attributeId = event.dataTransfer.getData('text/plain')
    
    const currentColumns = this.getCurrentColumns()
    currentColumns.push({
      id: attributeId,
      sequence: currentColumns.length + 1
    })

    await this.updateReport({ columns: currentColumns })
    
    // Refresh the canvas via Turbo
    this.element.requestSubmit()
  }

  async removeColumn(event) {
    const column = event.target.closest('[data-column-id]')
    const columnId = column.dataset.columnId
    
    const currentColumns = this.getCurrentColumns()
                              .filter(col => col.id !== columnId)
                              .map((col, index) => ({ ...col, sequence: index + 1 }))

    await this.updateReport({ columns: currentColumns })
    
    // Refresh the canvas via Turbo
    this.element.requestSubmit()
  }

  getCurrentColumns() {
    const columns = Array.from(this.canvasTarget.querySelectorAll('[data-column-id]'))
    return columns.map((col, index) => ({
      id: col.dataset.columnId,
      sequence: index + 1
    }))
  }

  async updateReport(columnConfig) {
    const reportId = this.element.dataset.reportId
    await fetch(`/datalab/designer/${reportId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        datalab_report: {
          column_config: columnConfig
        }
      })
    })
  }
}
