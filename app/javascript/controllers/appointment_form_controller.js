import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["professional", "date", "month", "year", "duration", "time"]

  connect() {
    this.updateTimes()
  }

  updateTimes() {
    const professional = this.professionalTarget.value
    const day = this.dateTarget.value.padStart(2, '0')
    const month = this.monthTarget.value.padStart(2, '0')
    const year = this.yearTarget.value
    const date = `${year}-${month}-${day}`
    // duration não é mais necessário para working_hours
    if (!professional || !date || isNaN(Date.parse(date))) return

    fetch(`/professionals/${professional}/working_hours?date=${date}`)
      .then(response => {
        if (!response.ok) throw new Error("Erro na resposta do servidor")
        return response.json()
      })
      .then(data => {
        // Sempre mostra todas as opções de horário (08:00 até 18:45 de 15 em 15 minutos)
        this.timeTarget.innerHTML = '<option value="">Selecione</option>'
        let horarios = [];
        let start = 8 * 60; // 08:00 em minutos
        let end = 18 * 60 + 45; // 18:45 em minutos
        for (let min = start; min <= end; min += 15) {
          let h = Math.floor(min / 60);
          let m = min % 60;
          horarios.push(`${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`);
        }
        horarios.forEach(time => {
          const option = document.createElement('option')
          option.value = time
          option.textContent = time
          this.timeTarget.appendChild(option)
        })
      })
      .catch(error => {
        console.error("Erro ao buscar horários do expediente:", error)
        this.timeTarget.innerHTML = '<option value="">Erro ao carregar horários</option>'
      })
  }
}
