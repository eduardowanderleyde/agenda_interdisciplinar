import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('click', this.handleClick.bind(this));
  }

  handleClick(e) {
    if (e.target.classList.contains('excluir-agendamento')) {
      e.preventDefault();
      const btn = e.target;
      const id = btn.getAttribute('data-id');
      if (confirm('Deseja realmente excluir este agendamento?')) {
        fetch(`/appointments/${id}`, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          }
        }).then(resp => {
          if (resp.ok) {
            btn.parentElement.remove();
          } else {
            alert('Erro ao excluir agendamento!');
          }
        });
      }
    }
  }
} 