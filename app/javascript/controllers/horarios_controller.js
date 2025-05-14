import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["inicio", "fim", "list", "item", "error"]

  connect() {
    // alert('Stimulus conectou!');
    console.log('[horarios] Entrando no connect do controller!');
    this.form = this.element.closest('form')
    this.handleSubmitBound = this.handleSubmit.bind(this)
    this.form.addEventListener('submit', this.handleSubmitBound)
    console.log('[horarios] Saiu do connect, controller conectado!');
  }

  disconnect() {
    if (this.form) {
      this.form.removeEventListener('submit', this.handleSubmitBound)
    }
  }

  // Aceita 16h, 16:00, 08h, 08:00
  parseHour(str) {
    const match = str.match(/^(\d{2})(h|:)?(\d{2})?$/)
    if (!match) return null
    let hour = match[1]
    let min = match[3] || '00'
    if (min.length === 1) min = '0' + min
    return `${hour}:${min}`
  }

  addIntervalo(e) {
    console.log('[horarios] Entrou no addIntervalo!');
    e.preventDefault()
    const dia = e.target.getAttribute('data-dia')
    console.log('[horarios] Clique no botão Adicionar para o dia:', dia)
    // Busca os inputs de início/fim e a lista do dia correto
    const inicioInput = this.element.querySelector(`input[data-horarios-target='inicio'][data-dia='${dia}']`)
    const fimInput = this.element.querySelector(`input[data-horarios-target='fim'][data-dia='${dia}']`)
    const list = this.element.querySelector(`ul[data-horarios-target='list'][data-dia='${dia}']`)
    const errorDiv = this.element.querySelector(`div[data-horarios-target='error'][data-dia='${dia}']`)
    console.log('[horarios] Inputs encontrados:', {inicioInput, fimInput, list, errorDiv})
    const inicio = inicioInput.value.trim()
    const fim = fimInput.value.trim()
    console.log('[horarios] Valores lidos:', {inicio, fim})
    const inicioFormatado = this.parseHour(inicio)
    const fimFormatado = this.parseHour(fim)
    console.log('[horarios] Valores formatados:', {inicioFormatado, fimFormatado})
    if (!inicioFormatado || !fimFormatado) {
      errorDiv.style.display = ''
      errorDiv.textContent = 'Formato inválido. Use 16h, 16:00, 08h, 08:00.'
      console.log('[horarios] Formato inválido!')
      return
    }
    errorDiv.style.display = 'none'
    const valor = `${inicioFormatado} - ${fimFormatado}`
    const exists = Array.from(list.querySelectorAll('input[type=hidden]')).some(i => i.value === valor)
    console.log('[horarios] Já existe?', exists)
    if (!exists) {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = `professional[available_hours][${dia}][]`
      input.value = valor
      const li = document.createElement('li')
      li.className = 'flex items-center bg-gray-100 rounded px-2 py-1 mb-1'
      li.innerHTML = `<span data-horarios-target=\"item\" class=\"mr-2 text-xs font-medium\">${valor}</span><button type=\"button\" class=\"text-red-600 ml-1 text-lg\" data-action=\"click->horarios#remove\">&times;</button>`
      li.appendChild(input)
      list.appendChild(li)
      console.log('[horarios] Horário adicionado na lista:', valor)
    } else {
      console.log('[horarios] Horário já estava na lista, não adicionou.')
    }
    inicioInput.value = ''
    fimInput.value = ''
    console.log('[horarios] Saiu do addIntervalo!');
  }

  handleSubmit(e) {
    // Para cada dia, se houver valores nos campos, adiciona como hidden
    this.inicioTargets.forEach((inicioInput, idx) => {
      const dia = inicioInput.getAttribute('data-dia')
      const fimInput = this.fimTargets.find(f => f.getAttribute('data-dia') === dia)
      const list = this.listTargets.find(l => l.getAttribute('data-dia') === dia)
      const errorDiv = this.errorTargets.find(er => er.getAttribute('data-dia') === dia)
      const inicio = inicioInput.value.trim()
      const fim = fimInput.value.trim()
      if (inicio || fim) {
        const inicioFormatado = this.parseHour(inicio)
        const fimFormatado = this.parseHour(fim)
        if (!inicioFormatado || !fimFormatado) {
          errorDiv.style.display = ''
          errorDiv.textContent = 'Formato inválido. Use 16h, 16:00, 08h, 08:00.'
          e.preventDefault()
          return
        }
        errorDiv.style.display = 'none'
        const valor = `${inicioFormatado} - ${fimFormatado}`
        const exists = Array.from(list.querySelectorAll('input[type=hidden]')).some(i => i.value === valor)
        if (!exists) {
          const input = document.createElement('input')
          input.type = 'hidden'
          input.name = `professional[available_hours][${dia}][]`
          input.value = valor
          const li = document.createElement('li')
          li.className = 'flex items-center bg-gray-100 rounded px-2 py-1 mb-1'
          li.innerHTML = `<span data-horarios-target=\"item\" class=\"mr-2 text-xs font-medium\">${valor}</span><button type=\"button\" class=\"text-red-600 ml-1 text-lg\" data-action=\"click->horarios#remove\">&times;</button>`
          li.appendChild(input)
          list.appendChild(li)
        }
        inicioInput.value = ''
        fimInput.value = ''
      }
    })
  }

  remove(event) {
    event.target.closest('li').remove()
  }

  adicionarHorario(event) {
    const btn = event.currentTarget;
    const dia = btn.getAttribute('data-dia');
    const diaCheckbox = document.querySelector(`input[name="professional[available_days][]"][value="${dia}"]`);
    if (!diaCheckbox.checked) {
      this.showToast('Marque o checkbox do dia primeiro!', '#f87171');
      return;
    }
    const inicio = document.querySelector(`input.js-inicio[data-dia="${dia}"]`).value.trim();
    const fim = document.querySelector(`input.js-fim[data-dia="${dia}"]`).value.trim();
    if (!inicio || !fim) {
      this.showToast('Preencha início e fim!', '#f87171');
      return;
    }
    const lista = document.getElementById(`lista-horarios-${dia}`);
    const texto = `${inicio} - ${fim}`;
    const horariosExistentes = Array.from(lista.querySelectorAll('li span')).map(span => span.textContent.trim());
    const conflito = horariosExistentes.some(intervalo => {
      const [existeInicio, existeFim] = intervalo.split(' - ');
      return (inicio < existeFim && fim > existeInicio);
    });
    if (conflito) {
      this.showToast('Este intervalo se sobrepõe com outro existente!', '#f87171');
      return;
    }
    // Confirmação antes de adicionar
    if (!confirm(`Você quer mesmo adicionar o horário ${texto} para ${this.diaPt(dia)}?`)) {
      return;
    }
    // Adiciona à lista
    const li = document.createElement('li');
    li.className = 'flex items-center bg-green-100 text-green-900 rounded px-3 py-1 mb-1 font-semibold text-xs shadow-sm';
    li.innerHTML = `<span>${texto}</span>
      <input type="hidden" name="professional[available_hours][${dia}][]" value="${texto}">
      <button type="button" onclick="this.parentElement.remove()" class="ml-2 text-red-600 hover:text-red-800 font-bold text-lg bg-transparent border-none cursor-pointer">&times;</button>`;
    lista.appendChild(li);
    this.showToast('Horário adicionado com sucesso!', '#22c55e');
    document.querySelector(`input.js-inicio[data-dia="${dia}"]`).value = '';
    document.querySelector(`input.js-fim[data-dia="${dia}"]`).value = '';
  }

  capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  diaPt(dia) {
    const map = {
      monday: 'Segunda',
      tuesday: 'Terça',
      wednesday: 'Quarta',
      thursday: 'Quinta',
      friday: 'Sexta'
    };
    return map[dia] || this.capitalize(dia);
  }

  showToast(msg, color) {
    const alertDiv = document.createElement('div');
    alertDiv.textContent = msg;
    alertDiv.style.position = 'fixed';
    alertDiv.style.top = '40px';
    alertDiv.style.left = '50%';
    alertDiv.style.transform = 'translateX(-50%)';
    alertDiv.style.background = color;
    alertDiv.style.color = 'white';
    alertDiv.style.padding = '16px 32px';
    alertDiv.style.borderRadius = '12px';
    alertDiv.style.fontSize = '1.1rem';
    alertDiv.style.boxShadow = '0 2px 16px 0 rgba(0,0,0,0.10)';
    alertDiv.style.zIndex = '9999';
    document.body.appendChild(alertDiv);
    setTimeout(() => { alertDiv.remove(); }, 1500);
  }
} 