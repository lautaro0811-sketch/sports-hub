import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.fp = flatpickr(this.inputTarget, {
      inline: true,
      defaultDate: this.inputTarget.value || new Date(),
      onChange: (selectedDates, dateStr, instance) => {
        this.inputTarget.value = dateStr;
        // Disparar programáticamente el envío del formulario
        if (this.inputTarget.form) {
          this.inputTarget.form.requestSubmit();
        }
      }
    })
  }

  disconnect() {
    if (this.fp) {
      this.fp.destroy()
    }
  }
}
