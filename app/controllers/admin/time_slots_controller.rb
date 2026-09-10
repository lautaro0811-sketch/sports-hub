module Admin
  class TimeSlotsController < BaseController
    before_action :set_court

    def index
      @time_slots = @court.time_slots.order(:day_of_week, :start_time)
      @time_slot = @court.time_slots.build
    end

    def create
      @time_slot = @court.time_slots.build(time_slot_params)

      if @time_slot.save
        redirect_to admin_court_time_slots_path(@court), notice: "Tarifa horaria creada correctamente."
      else
        @time_slots = @court.time_slots.order(:day_of_week, :start_time)
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      @time_slot = @court.time_slots.find(params[:id])
      @time_slot.destroy
      redirect_to admin_court_time_slots_path(@court), notice: "Tarifa horaria eliminada."
    end

    private

    def set_court
      @court = Court.includes(:sports_complex, :sport).find(params[:court_id])
    end

    def time_slot_params
      params.require(:time_slot).permit(:day_of_week, :start_time, :end_time, :price)
    end
  end
end
