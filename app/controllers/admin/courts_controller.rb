module Admin
    class CourtsController < BaseController
        before_action :set_court, only: [:edit, :update, :destroy]
        
    def index
      @courts = Court.includes(:sports_complex, :sport).all
    end

    def new
      @court = Court.new
    end

    def create
      @court = Court.new(court_params)
      if @court.save
        redirect_to admin_courts_path, notice: "Cancha creada exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @court.update(court_params)
        redirect_to admin_courts_path, notice: "Cancha actualizada exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @court.destroy
      redirect_to admin_courts_path, notice: "Cancha eliminada."
    end

    private

    def set_court
      @court = Court.find(params[:id])
    end

    def court_params
      params.require(:court).permit(:name, :sports_complex_id, :sport_id, :surface_type, :is_active)
    end
  end
end