module Admin
  class SportsComplexesController < BaseController
    before_action :set_sports_complex, only: [ :edit, :update, :destroy ]

    def index
      @sports_complexes = SportsComplex.all
    end

    def new
      @sports_complex = SportsComplex.new
    end

    def create
      @sports_complex = SportsComplex.new(sports_complex_params)
      if @sports_complex.save
        redirect_to admin_sports_complexes_path, notice: "Complejo deportivo creado exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @sports_complex.update(sports_complex_params)
        redirect_to admin_sports_complexes_path, notice: "Complejo deportivo actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @sports_complex.destroy
      redirect_to admin_sports_complexes_path, notice: "Complejo deportivo eliminado."
    end

    private

    def set_sports_complex
      @sports_complex = SportsComplex.find(params[:id])
    end

    def sports_complex_params
      params.require(:sports_complex).permit(:name, :address, :city, :phone, :cover_photo)
    end
  end
end
