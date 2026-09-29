module Admin
  class DashboardController < BaseController
    CourtStatus = Struct.new(:court, :status, :next_reservation, keyword_init: true)

    def index
      @selected_date = params[:date].presence ? Date.parse(params[:date]) : Date.current
      today = @selected_date

      if @selected_date == Date.current
        now_time = Time.current.strftime("%H:%M:%S")
      elsif @selected_date < Date.current
        now_time = "23:59:59"
      else
        now_time = "00:00:00"
      end

      @sports_complexes = SportsComplex.order(:name)
      @selected_complex_id = params[:complex_id].presence
      @selected_complex = @sports_complexes.find { |sc| sc.id.to_s == @selected_complex_id.to_s } if @selected_complex_id

      @status_filter = params[:status_filter] || "Todos"

      base = base_reservations_scope
      today_scope = base.for_date(today).not_cancelled

      # ── KPI Cards ──
      @today_reservations_total = today_scope.count
      @today_reservations_finished = today_scope.finished_before(now_time).count
      @today_remaining_shifts = today_scope.after_time(now_time).count

      # Canchas activas en este momento (obtenidas en 1 query reutilizable)
      current_court_ids = today_scope.in_progress_at(now_time).pluck(:court_id)
      @current_active_courts = current_court_ids.uniq.size
      @total_courts = Court.where(is_active: true).by_sports_complex(@selected_complex_id).count

      # Cancelaciones de hoy
      @today_cancellations = base.for_date(today).where(status: :cancelled).count

      # ── Sección "Ahora Mismo": reservas en curso ──
      @current_reservations = today_scope
        .in_progress_at(now_time)
        .includes(:user, court: [ :sport, :sports_complex ])
        .order("reservations.start_time ASC")

      # ── Próximos Turnos (reutilizado para el próximo turno destacado) ──
      @upcoming_shifts = today_scope
        .after_time(now_time)
        .includes(:user, court: [ :sport, :sports_complex ])
        .order("reservations.start_time ASC")
        .limit(5)
        .to_a

      # ── Próximo Turno (destacado) ──
      @next_shift = @upcoming_shifts.first
      @minutes_until_next = calculate_minutes_until(@next_shift) if @next_shift

      # ── Estado de Canchas ──
      @court_statuses = build_court_statuses(today, now_time, current_court_ids)

      @kpi_filter = params[:kpi_filter]

      # ── Agenda Diaria ──
      build_daily_schedule(today, today_scope, base, now_time)

      if @daily_schedule.is_a?(Array)
        @pagy, @daily_schedule = pagy_array(@daily_schedule, limit: 15)
      else
        @pagy, @daily_schedule = pagy(@daily_schedule, limit: 15)
      end
    end

    private

    def base_reservations_scope
      @selected_complex_id.present? ? Reservation.by_sports_complex(@selected_complex_id) : Reservation.all
    end

    def calculate_minutes_until(reservation)
      now_seconds = Time.current.seconds_since_midnight
      start_seconds = reservation.start_time.seconds_since_midnight
      ((start_seconds - now_seconds) / 60.0).ceil
    end

    def build_court_statuses(today, now_time, current_court_ids)
      active_courts = Court.where(is_active: true)
        .by_sports_complex(@selected_complex_id)
        .includes(:sport, :sports_complex)
        .order(:name)

      # Próximas reservas del día agrupadas por cancha (1 query)
      next_reservations_by_court = base_reservations_scope
        .for_date(today)
        .not_cancelled
        .after_time(now_time)
        .includes(:user)
        .order("reservations.start_time ASC")
        .group_by(&:court_id)

      active_courts.map do |court|
        next_res = next_reservations_by_court[court.id]&.first

        status = if current_court_ids.include?(court.id)
                   :in_use
        elsif next_res
                   :upcoming
        else
                   :available
        end

        CourtStatus.new(
          court: court,
          status: status,
          next_reservation: next_res
        )
      end
    end

    def build_daily_schedule(date, today_scope, base_scope, now_time)
      # Determinamos el scope inicial basado en el KPI seleccionado
      scope = case @kpi_filter
      when "en_uso"
                today_scope.in_progress_at(now_time)
      when "restantes"
                today_scope.after_time(now_time)
      when "canceladas"
                base_scope.for_date(date).where(status: :cancelled)
      else
                today_scope
      end

      case @status_filter
      when "Ocupados"
        @daily_schedule = scope
          .where("reservations.status = :confirmed OR reservations.payment_status = :paid",
                 confirmed: Reservation.statuses[:confirmed],
                 paid: Reservation.payment_statuses[:paid])
          .includes(:user, court: [ :sport, :sports_complex ])
          .order("reservations.start_time ASC")
      when "Libres", "Todos"
        if @kpi_filter.present? && @status_filter == "Todos"
          @daily_schedule = scope.includes(:user, court: [ :sport, :sports_complex ]).order("reservations.start_time ASC").to_a
        else
          @daily_schedule = []
          courts = Court.where(is_active: true).by_sports_complex(@selected_complex_id).includes(:sport, :sports_complex, :time_slots)
          reservations_by_court = scope.includes(:user, court: [ :sport, :sports_complex ]).group_by(&:court_id)

          if @status_filter == "Todos"
            @daily_schedule += scope.includes(:user, court: [ :sport, :sports_complex ]).to_a
          end

          courts.each do |court|
          court_reservations = reservations_by_court[court.id] || []
          day_time_slots = court.time_slots.select { |ts| ts.day_of_week == date.wday }

          if day_time_slots.any?
            day_time_slots.each do |ts|
              slot_start_sec = ts.start_time.seconds_since_midnight
              slot_end_sec = ts.end_time.seconds_since_midnight

              has_reservation = court_reservations.any? do |res|
                res_start_sec = res.start_time.seconds_since_midnight
                res_end_sec = res.end_time.seconds_since_midnight
                res_start_sec < slot_end_sec && res_end_sec > slot_start_sec
              end

              unless has_reservation
                @daily_schedule << { type: :free, court: court, start_time: ts.start_time, end_time: ts.end_time }
              end
            end
          else
            # Fallback a (8..22) si no hay time_slots definidos
            (8..22).each do |hour|
              slot_start_sec = hour * 3600
              slot_end_sec = (hour + 1) * 3600

              has_reservation = court_reservations.any? do |res|
                res_start_sec = res.start_time.seconds_since_midnight
                res_end_sec = res.end_time.seconds_since_midnight
                res_start_sec < slot_end_sec && res_end_sec > slot_start_sec
              end

              unless has_reservation
                slot_start_time = Time.zone.parse("#{hour}:00:00") || Time.current.change(hour: hour, min: 0)
                slot_end_time = Time.zone.parse("#{hour + 1}:00:00") || Time.current.change(hour: hour + 1, min: 0)
                @daily_schedule << { type: :free, court: court, start_time: slot_start_time, end_time: slot_end_time }
              end
            end
          end
        end
        end

        @daily_schedule.sort_by! do |item|
          start_time = item.is_a?(Hash) ? item[:start_time] : item.start_time
          start_time.seconds_since_midnight
        end
      end
    end
  end
end
