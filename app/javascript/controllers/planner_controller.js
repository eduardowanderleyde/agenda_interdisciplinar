import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "startTime", "roomId"]

  open(event) {
    const button = event.currentTarget
    const date = button.dataset.plannerDate
    const time = button.dataset.plannerTime
    const roomId = button.dataset.plannerRoom

    this.startTimeTarget.value = `${date} ${time}`
    this.roomIdTarget.value = roomId

    this.modalTarget.classList.remove("hidden")
  }

  close() {
    this.modalTarget.classList.add("hidden")
  }
}
