import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timerId = setInterval(() => {
      if (!this.element.isConnected) {
        clearInterval(this.timerId)
        this.timerId = null
        return
      }

      this.element.reload()
    }, 60000)
  }

  disconnect() {
    if (this.timerId) {
      clearInterval(this.timerId)
      this.timerId = null
    }
  }
}
