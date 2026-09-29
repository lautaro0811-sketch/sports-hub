module Admin
  class DashboardController < BaseController
    CourtStatus = Struct.new(:court, :status, :next_reservation, keyword_init: true)

    def index
      today = Date.current
      now_time = Time.current.strftime("%H:%M:%S")

      @sports_complexes = SportsComplex.order(:name)
      @selected_complex_id = params[:complex_id].presence
      @selected_complex = @sports_complexes.find { |sc| sc.id.to_s == @selected_complex_id.to_s } if @selected_complex_id

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
  end
end
