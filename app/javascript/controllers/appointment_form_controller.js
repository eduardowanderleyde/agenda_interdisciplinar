import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["professional", "date", "duration", "time"]

  connect() {
    this.updateTimes()
  }

  updateTimes() {
    const professional = this.professionalTarget.value
    const date = this.dateTarget.value
    const duration = this.durationTarget.value

    if (!professional || !date || !duration) return

    fetch(`/professionals/${professional}/available_times?date=${date}&duration=${duration}`)
      .then(response => {
        if (!response.ok) throw new Error("Erro na resposta do servidor");
        return response.json();
      })
      .then(data => {
        this.timeTarget.innerHTML = '<option value="">Selecione</option>'
        data.times.forEach(time => {
          const option = document.createElement('option')
          option.value = time
          option.textContent = time
          this.timeTarget.appendChild(option)
        })
      })
      .catch(error => {
        console.error("Erro ao buscar horários disponíveis:", error);
        this.timeTarget.innerHTML = '<option value="">Erro ao carregar horários</option>';
      });
  }
} 