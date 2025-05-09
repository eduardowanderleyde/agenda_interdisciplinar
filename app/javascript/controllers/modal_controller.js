import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    console.log("Fechando modal...");
    this.element.remove();
  }
} 