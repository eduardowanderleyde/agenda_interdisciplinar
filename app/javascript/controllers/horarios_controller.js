import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["inicio", "fim", "list", "item"]

  connect() {
    this.form = this.element.closest('form')
    this.handleSubmitBound = this.handleSubmit.bind(this)
    this.form.addEventListener('submit', this.handleSubmitBound)
  }

  disconnect() {
    if (this.form) {
      this.form.removeEventListener('submit', this.handleSubmitBound)
    }
  }

  handleSubmit(e) {
    const inicio = this.inicioTarget.value.trim()
    const fim = this.fimTarget.value.trim()
    if (inicio && fim && /^\d{2}:\d{2}$/.test(inicio) && /^\d{2}:\d{2}$/.test(fim)) {
      const valor = `${inicio} - ${fim}`
      const exists = Array.from(this.listTarget.querySelectorAll('input[type=hidden]')).some(i => i.value === valor)
      if (!exists) {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = 'professional[available_hours][]'
        input.value = valor
        this.listTarget.appendChild(input)
      }
      this.inicioTarget.value = ''
      this.fimTarget.value = ''
    }
  }

  addIntervalo(e) {
    e.preventDefault()
    const inicio = this.inicioTarget.value.trim()
    const fim = this.fimTarget.value.trim()
    if (inicio && fim && /^\d{2}:\d{2}$/.test(inicio) && /^\d{2}:\d{2}$/.test(fim)) {
      const valor = `${inicio} - ${fim}`
      const exists = Array.from(this.listTarget.querySelectorAll('input[type=hidden]')).some(i => i.value === valor)
      if (!exists) {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = 'professional[available_hours][]'
        input.value = valor
        this.listTarget.appendChild(input)
        const li = document.createElement('li')
        li.className = 'flex items-center bg-gray-100 rounded px-2 py-1 mb-1'
        li.innerHTML = `<span data-horarios-target="item" class="mr-2">${valor}</span><button type="button" class="text-red-600 ml-1" data-action="click->horarios#remove">&times;</button>`
        li.appendChild(input)
        this.listTarget.appendChild(li)
      }
      this.inicioTarget.value = ''
      this.fimTarget.value = ''
    }
  }

  remove(event) {
    event.target.closest('li').remove()
  }
} 