import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["paciente", "dia", "horario", "especialidade", "buscar", "sugestoes"]

  connect() {
    console.log("Stimulus suggestion conectado!");
    const btnSimular = document.getElementById('btn-simular-horario');
    if (btnSimular) {
      btnSimular.addEventListener('click', this.simularHorarioSemana.bind(this));
    }
  }

  simularHorarioSemana() {
    const simulacaoDiv = document.getElementById('simulacao-horario-semanal');
    if (simulacaoDiv) {
      simulacaoDiv.innerHTML = '<div class="text-gray-500">Simulando organização da semana...</div>';
      fetch('/suggestions/simulate_schedule')
        .then(r => r.text())
        .then(html => {
          simulacaoDiv.innerHTML = html;
        })
        .catch(() => {
          simulacaoDiv.innerHTML = '<div class="text-red-600">Erro ao simular a semana.</div>';
        });
    }
  }

  updateDias() {
    const pacienteId = this.pacienteTarget.value
    this.diaTarget.innerHTML = '<option value="">Carregando...</option>'
    this.diaTarget.disabled = true
    this.horarioTarget.innerHTML = '<option value="">Selecione o horário</option>'
    this.horarioTarget.disabled = true
    this.especialidadeTarget.innerHTML = '<option value="">Selecione a especialidade</option>'
    this.especialidadeTarget.disabled = true
    this.buscarTarget.disabled = true
    if (!pacienteId) return
    fetch(`/suggestions/dias?patient_id=${pacienteId}`)
      .then(r => r.json())
      .then(data => {
        this.diaTarget.innerHTML = '<option value="">Selecione o dia</option>'
        data.dias.forEach(d => {
          const opt = document.createElement('option')
          opt.value = d.value
          opt.textContent = d.label
          this.diaTarget.appendChild(opt)
        })
        this.diaTarget.disabled = false
      })
  }

  updateHorarios() {
    const pacienteId = this.pacienteTarget.value
    const dia = this.diaTarget.value
    this.horarioTarget.innerHTML = '<option value="">Carregando...</option>'
    this.horarioTarget.disabled = true
    this.especialidadeTarget.innerHTML = '<option value="">Selecione a especialidade</option>'
    this.especialidadeTarget.disabled = true
    this.buscarTarget.disabled = true
    if (!pacienteId || !dia) return
    fetch(`/suggestions/horarios?patient_id=${pacienteId}&dia=${encodeURIComponent(dia)}`)
      .then(r => r.json())
      .then(data => {
        this.horarioTarget.innerHTML = '<option value="">Selecione o horário</option>'
        data.horarios.forEach(h => {
          const opt = document.createElement('option')
          opt.value = h
          opt.textContent = h
          this.horarioTarget.appendChild(opt)
        })
        this.horarioTarget.disabled = false
      })
  }

  updateEspecialidades() {
    const pacienteId = this.pacienteTarget.value
    if (!pacienteId) return
    this.especialidadeTarget.innerHTML = '<option value="">Carregando...</option>'
    this.especialidadeTarget.disabled = true
    this.buscarTarget.disabled = true
    fetch(`/suggestions/especialidades?patient_id=${pacienteId}`)
      .then(r => r.json())
      .then(data => {
        this.especialidadeTarget.innerHTML = '<option value="">Selecione a especialidade</option>'
        data.especialidades.forEach(e => {
          const opt = document.createElement('option')
          opt.value = e.id
          opt.textContent = e.name
          this.especialidadeTarget.appendChild(opt)
        })
        this.especialidadeTarget.disabled = false
        this.habilitarBuscar()
      })
  }

  habilitarBuscar() {
    const pacienteId = this.pacienteTarget.value
    const dia = this.diaTarget.value
    const horario = this.horarioTarget.value
    const especialidadeId = this.especialidadeTarget.value
    this.buscarTarget.disabled = !(pacienteId && dia && horario && especialidadeId)
  }

  buscarSugestoes() {
    const pacienteId = this.pacienteTarget.value
    const dia = this.diaTarget.value
    const horario = this.horarioTarget.value
    const especialidadeId = this.especialidadeTarget.value
    if (!pacienteId || !dia || !horario || !especialidadeId) return
    this.sugestoesTarget.innerHTML = '<div class="text-gray-500">Buscando sugestões...</div>'
    fetch(`/suggestions/sugestoes?patient_id=${pacienteId}&dia=${encodeURIComponent(dia)}&horario=${encodeURIComponent(horario)}&especialidade_id=${especialidadeId}`)
      .then(r => r.json())
      .then(data => {
        let html = ''
        if (data.profissionais.length === 0) {
          html += '<div class="text-gray-500">Nenhum profissional disponível para este horário e especialidade.</div>'
        } else {
          html += '<div class="mb-2 font-semibold">Profissionais disponíveis:</div>'
          html += '<ul class="mb-4">'
          data.profissionais.forEach(p => {
            html += `<li class='mb-1'>${p.name}</li>`
          })
          html += '</ul>'
        }
        this.sugestoesTarget.innerHTML = html
      })
  }
}
