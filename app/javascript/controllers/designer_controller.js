import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["draggable", "availableAttributes", "canvas"]

  connect() {
    // Hide items that are already in the canvas from available attributes
    this.hideCanvasItemsFromAvailable()
    this.initializeDragAndDrop()
  }

  hideCanvasItemsFromAvailable() {
    // Get all items in the canvas
    const canvasItems = this.canvasTarget.querySelectorAll('[data-attribute-id]')
    
    // Hide each corresponding item in available attributes
    canvasItems.forEach(item => {
      const attributeId = item.dataset.attributeId
      this.hideFromAvailable(attributeId)
    })
  }

  initializeDragAndDrop() {
    // Make items draggable
    this.draggableTargets.forEach(draggable => {
      this.initializeDraggable(draggable)
    })

    // Set up drop zones
    this.availableAttributesTarget.addEventListener('dragover', this.handleDragOver.bind(this))
    this.availableAttributesTarget.addEventListener('drop', this.handleDrop.bind(this))
    this.canvasTarget.addEventListener('dragover', this.handleDragOver.bind(this))
    this.canvasTarget.addEventListener('drop', this.handleDrop.bind(this))
  }

  handleDragStart(event) {
    const container = event.target.closest('[data-designer-target="canvas"], [data-designer-target="availableAttributes"]')
    event.dataTransfer.setData('text/plain', JSON.stringify({
      id: event.target.dataset.attributeId,
      name: event.target.dataset.attributeName,
      description: event.target.dataset.attributeDescription,
      sourceZone: container ? container.dataset.designerTarget : null
    }))
  }

  handleDragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }

  handleDrop(event) {
    event.preventDefault()
    const data = JSON.parse(event.dataTransfer.getData('text/plain'))
    
    // Find the actual drop zone container, not the draggable element
    const dropZone = event.target.closest('[data-designer-target="canvas"], [data-designer-target="availableAttributes"]')
    if (!dropZone) {
      console.error('No valid drop zone found')
      return
    }
    
    const targetZone = dropZone.dataset.designerTarget
    console.log('Drop event:', {
      sourceZone: data.sourceZone,
      targetZone: targetZone,
      data: data
    })
    
    // Don't do anything if dropped in same zone
    if (data.sourceZone === targetZone) {
      console.log('Same zone, ignoring drop')
      return
    }

    if (targetZone === 'canvas') {
      console.log('Adding to canvas')
      this.addToCanvas(data)
      this.hideFromAvailable(data.id)
    } else if (targetZone === 'availableAttributes') {
      console.log('Moving back to available')
      this.removeFromCanvas(data.id)
      this.showInAvailable(data.id)
    }

    this.updateColumnConfig()
  }

  hideFromAvailable(attributeId) {
    const element = this.availableAttributesTarget.querySelector(`[data-attribute-id="${attributeId}"]`)
    if (element) element.classList.add('hidden')
  }

  showInAvailable(attributeId) {
    const element = this.availableAttributesTarget.querySelector(`[data-attribute-id="${attributeId}"]`)
    if (element) element.classList.remove('hidden')
  }

  addToCanvas(data) {
    const columnHtml = this.buildColumnHtml(data)
    this.canvasTarget.querySelector('.grid').insertAdjacentHTML('beforeend', columnHtml)
    
    // Initialize drag for the newly added element
    const newElement = this.canvasTarget.querySelector(`[data-attribute-id="${data.id}"]`)
    this.initializeDraggable(newElement)
  }

  initializeDraggable(element) {
    element.setAttribute('draggable', true)
    element.addEventListener('dragstart', this.handleDragStart.bind(this))
  }

  removeFromCanvas(attributeId) {
    const element = this.canvasTarget.querySelector(`[data-attribute-id="${attributeId}"]`)
    if (element) element.remove()
  }

  buildColumnHtml(data) {
    return `
      <div class="flex flex-row justify-between items-start h-16 p-2 bg-sky-100 rounded border border-sky-500 cursor-move"
           data-designer-target="draggable"
           data-attribute-id="${data.id}"
           data-attribute-name="${data.name}"
           data-attribute-description="${data.description}">
        <div>
          <div class="text-sm font-medium">${data.name}</div>
          <div class="text-xs text-gray-600">${data.description}</div>
        </div>
      </div>
    `
  }

  async updateColumnConfig() {
    const columns = Array.from(this.canvasTarget.querySelectorAll('[data-attribute-id]')).map(el => ({
      id: el.dataset.attributeId,
      name: el.dataset.attributeName,
      description: el.dataset.attributeDescription
    }))

    try {
      await fetch(this.element.dataset.updateUrl, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ column_config: { columns } })
      })
    } catch (error) {
      console.error('Failed to update column configuration:', error)
    }
  }
}