import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["availableAttributes", "canvas", "draggable"]

  connect() {
    this.draggableTargets.forEach(draggable => {
      draggable.setAttribute('draggable', true)
      draggable.addEventListener('dragstart', this.dragStart.bind(this))
    })

    this.canvasTarget.addEventListener('dragover', this.dragOver.bind(this))
    this.canvasTarget.addEventListener('drop', this.drop.bind(this))
  }

  dragStart(event) {
    const target = event.target
    event.dataTransfer.setData('text/plain', JSON.stringify({
      id: target.dataset.attributeId,
      name: target.dataset.attributeName,
      description: target.dataset.attributeDescription
    }))
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }

  async drop(event) {
    event.preventDefault()
    const data = JSON.parse(event.dataTransfer.getData('text/plain'))
    
    const columnConfig = {
      columns: Array.from(this.element.querySelectorAll('[data-column-id]')).map((el, index) => ({
        id: el.dataset.columnId,
        sequence: index + 1
      }))
    }

    // Add new column
    columnConfig.columns.push({
      id: data.id,
      sequence: columnConfig.columns.length + 1
    })

    // Save to server
    const response = await fetch(this.element.dataset.updateUrl, {
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

    if (response.ok) {
      const column = document.createElement('div')
      column.innerHTML = this.columnTemplate(data)
      this.canvasTarget.appendChild(column)
    }
  }

  removeColumn(event) {
    const column = event.target.closest('[data-column-id]')
    column.remove()
    this.updateColumnConfig()
  }

  async updateColumnConfig() {
    const columnConfig = {
      columns: Array.from(this.element.querySelectorAll('[data-column-id]')).map((el, index) => ({
        id: el.dataset.columnId,
        sequence: index + 1
      }))
    }

    await fetch(this.element.dataset.updateUrl, {
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

  columnTemplate(data) {
    return `
      <div class="flex items-center justify-between p-2 bg-gray-50 rounded border border-gray-200 mb-2" 
           data-column-id="${data.id}">
        <div>
          <div class="font-medium">${data.name}</div>
          <div class="text-sm text-gray-500">${data.description}</div>
        </div>
        <button type="button" 
                class="text-gray-400 hover:text-gray-500"
                data-action="click->designer#removeColumn">
          <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>
    `
  }
}
