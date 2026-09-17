module Admin
  class TimeSlotsController < BaseController
    before_action :set_court

    def index
      @time_slots = @court.time_slots.order(:day_of_week, :start_time)
      @time_slot = @court.time_slots.build

      @slots_by_day = TimeSlot::DAY_ORDER.each_with_object({}) do |day, hash|
        hash[day] = @time_slots.select { |s| s.day_of_week == day }
      end
    end

    def create
      # Extraer días seleccionados
      days = params[:days_of_week] || (params[:time_slot] && params[:time_slot][:day_of_week])
      days = Array(days).reject(&:blank?).map(&:to_i).uniq

      if days.empty?
        redirect_to admin_court_time_slots_path(@court), alert: "Debés seleccionar al menos un día de la semana."
        return
      end

      # Extraer horarios
      start_str = params[:start_time].presence || (params[:time_slot] && params[:time_slot][:start_time])
      end_str = params[:end_time].presence || (params[:time_slot] && params[:time_slot][:end_time])

      if start_str.blank? || end_str.blank?
        redirect_to admin_court_time_slots_path(@court), alert: "Debés indicar la hora de inicio y de fin."
        return
      end

      start_sec = PricingRule.seconds_since_midnight_for(start_str)
      end_sec = PricingRule.seconds_since_midnight_for(end_str)

      if start_sec.nil? || end_sec.nil? || end_sec <= start_sec
        redirect_to admin_court_time_slots_path(@court), alert: "La hora de fin debe ser posterior a la hora de inicio."
        return
      end

      # Calcular intervalos según duración
      duration_param = params[:slot_duration].presence || "exact"
      intervals = []

      if duration_param != "exact" && duration_param.to_i > 0
        step_sec = duration_param.to_i * 60
        curr = start_sec
        while curr + step_sec <= end_sec
          s_hour = format("%02d:%02d", curr / 3600, (curr % 3600) / 60)
          e_hour = format("%02d:%02d", (curr + step_sec) / 3600, ((curr + step_sec) % 3600) / 60)
          intervals << [ s_hour, e_hour ]
          curr += step_sec
        end

        if intervals.empty?
          redirect_to admin_court_time_slots_path(@court), alert: "La duración seleccionada (#{duration_param} min) es mayor que la franja horaria total."
          return
        end
      else
        intervals = [ [ start_str, end_str ] ]
      end

      created_count = 0
      skipped_errors = []

      ActiveRecord::Base.transaction do
        days.each do |day|
          intervals.each do |s_time, e_time|
            slot = @court.time_slots.build(
              day_of_week: day,
              start_time: s_time,
              end_time: e_time
            )

            if slot.save
              created_count += 1
            else
              skipped_errors.concat(slot.errors.full_messages)
            end
          end
        end
      end

      if created_count > 0
        notice_msg = "Se generaron exitosamente #{created_count} turno(s) de disponibilidad."
        if skipped_errors.any?
          notice_msg += " (Se omitieron #{skipped_errors.uniq.size} por ya existir o solaparse)."
        end
        redirect_to admin_court_time_slots_path(@court), notice: notice_msg
      else
        error_msg = skipped_errors.uniq.first || "No se pudieron crear los turnos."
        redirect_to admin_court_time_slots_path(@court), alert: error_msg
      end
    end

    def destroy
      @time_slot = @court.time_slots.find(params[:id])
      @time_slot.destroy
      redirect_to admin_court_time_slots_path(@court), notice: "Turno eliminado correctamente."
    end

    def destroy_day
      day = params[:day_of_week].to_i
      day_name = TimeSlot::DAYS[day] || "Día #{day}"
      slots = @court.time_slots.where(day_of_week: day)
      count = slots.count
      slots.destroy_all

      redirect_to admin_court_time_slots_path(@court), notice: "Se eliminaron los #{count} turno(s) del día #{day_name}."
    end

    def destroy_all
      count = @court.time_slots.count
      @court.time_slots.destroy_all

      redirect_to admin_court_time_slots_path(@court), notice: "Se vaciaron todos los turnos (#{count}) de la cancha #{@court.name}."
    end

    private

    def set_court
      @court = Court.includes(:sports_complex, :sport, :pricing_scheme).find(params[:court_id])
    end

    def time_slot_params
      params.require(:time_slot).permit(:day_of_week, :start_time, :end_time, :price, :price_multiplier)
    end
  end
end
