module Admin
  class DashboardController < BaseController
    CourtStatus = Struct.new(:court, :status, :next_reservation, keyword_init: true)

    def index
      today = Date.current
      now_time = Time.current.strftime("%H:%M:%S")

      @sports_complexes = SportsComplex.order(:name)
      @selected_complex_id = params[:complex_id].presence

      base = base_reservations_scope

      # ── KPI Cards ──

      # Reservas de hoy (no canceladas)
      today_scope = base.where(reservation_date: today).where.not(status: :cancelled)
      @today_reservations_total = today_scope.count
      @today_reservations_finished = today_scope
        .where("strftime('%H:%M:%S', reservations.end_time) <= ?", now_time).count

      # Turnos restantes hoy
      @today_remaining_shifts = today_scope
        .where("strftime('%H:%M:%S', reservations.start_time) > ?", now_time).count

      # Canchas activas en este momento
      @current_active_courts = base
        .where(reservation_date: today)
        .where.not(status: :cancelled)
        .where("strftime('%H:%M:%S', reservations.start_time) <= ? AND strftime('%H:%M:%S', reservations.end_time) > ?", now_time, now_time)
        .distinct
        .count(:court_id)

      @total_courts = Court.where(is_active: true).by_sports_complex(@selected_complex_id).count

      # Cancelaciones de hoy
      @today_cancellations = base
        .where(reservation_date: today, status: :cancelled)
        .count

      # ── Sección "Ahora Mismo": reservas en curso ──
      @current_reservations = base
        .includes(:user, court: [ :sport, :sports_complex ])
        .where(reservation_date: today)
        .where.not(status: :cancelled)
        .where("strftime('%H:%M:%S', reservations.start_time) <= ? AND strftime('%H:%M:%S', reservations.end_time) > ?", now_time, now_time)
        .order("reservations.start_time ASC")

      # ── Próximo Turno (destacado) ──
      @next_shift = base
        .includes(:user, court: [ :sport, :sports_complex ])
        .where(reservation_date: today)
        .where.not(status: :cancelled)
        .where("strftime('%H:%M:%S', reservations.start_time) > ?", now_time)
        .order("reservations.start_time ASC")
        .first

      @minutes_until_next = calculate_minutes_until(@next_shift) if @next_shift

      # ── Estado de Canchas ──
      @court_statuses = build_court_statuses(today, now_time)

      # ── Próximos Turnos (tabla) ──
      @upcoming_shifts = base
        .includes(:user, court: [ :sport, :sports_complex ])
        .where(reservation_date: today)
        .where.not(status: :cancelled)
        .where("strftime('%H:%M:%S', reservations.start_time) > ?", now_time)
        .order("reservations.start_time ASC")
        .limit(5)
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

    def build_court_statuses(today, now_time)
      active_courts = Court.where(is_active: true)
        .by_sports_complex(@selected_complex_id)
        .includes(:sport, :sports_complex)
        .order(:name)

      # IDs de canchas con reserva en curso (1 query)
      current_court_ids = base_reservations_scope
        .where(reservation_date: today)
        .where.not(status: :cancelled)
        .where("strftime('%H:%M:%S', reservations.start_time) <= ? AND strftime('%H:%M:%S', reservations.end_time) > ?", now_time, now_time)
        .pluck(:court_id)

      # Próximas reservas del día agrupadas por cancha (1 query)
      next_reservations_by_court = base_reservations_scope
        .includes(:user)
        .where(reservation_date: today)
        .where.not(status: :cancelled)
        .where("strftime('%H:%M:%S', reservations.start_time) > ?", now_time)
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
  end
end
