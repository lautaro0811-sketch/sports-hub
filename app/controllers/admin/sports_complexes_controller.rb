module Admin
  class SportsComplexesController < BaseController
    before_action :set_sports_complex, only: [ :edit, :update, :destroy ]

    def index
      @cities = SportsComplex.distinct.pluck(:city).compact_blank.sort

      sports_complexes_scope = SportsComplex.includes(:default_pricing_scheme, :courts)
                                            .search_by_name(params[:name])
                                            .by_city(params[:city])
                                            .order(:name)

      @pagy, @sports_complexes = pagy(sports_complexes_scope, limit: 10)
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
      params.require(:sports_complex).permit(:name, :address, :city, :phone, :cover_photo, :default_pricing_scheme_id)
    end
  end
end
