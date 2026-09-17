module Admin
  class PricingSchemesController < BaseController
    before_action :set_pricing_scheme, only: %i[show edit update destroy assign_courts]

    def index
      @pricing_schemes = PricingScheme.includes(:pricing_rules, :courts, sports_complexes: :courts).order(:name)
    end

    def show
      @rules_by_day = @pricing_scheme.rules_grouped_by_day
      @new_rule = @pricing_scheme.pricing_rules.build(multiplier: 1.0)
      @all_courts = Court.includes(:sports_complex, :sport).order("sports_complexes.name", "courts.name")
    end

    def new
      @pricing_scheme = PricingScheme.new
    end

    def create
      @pricing_scheme = PricingScheme.new(pricing_scheme_params)
      if @pricing_scheme.save
        redirect_to admin_pricing_scheme_path(@pricing_scheme), notice: "Esquema tarifario creado exitosamente. Ahora podés agregar sus reglas horarias."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @pricing_scheme.update(pricing_scheme_params)
        redirect_to admin_pricing_scheme_path(@pricing_scheme), notice: "Esquema tarifario actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @pricing_scheme.destroy
      redirect_to admin_pricing_schemes_path, notice: "Esquema tarifario eliminado."
    end

    def assign_courts
      selected_court_ids = Array(params[:court_ids]).map(&:to_i).reject(&:zero?)

      # Canchas que tenían este esquema pero fueron desmarcadas -> vuelven a heredar o quedan sin esquema (nil)
      @pricing_scheme.courts.where.not(id: selected_court_ids).update_all(pricing_scheme_id: nil)

      # Asignamos las canchas seleccionadas
      if selected_court_ids.any?
        Court.where(id: selected_court_ids).update_all(pricing_scheme_id: @pricing_scheme.id)
      end

      redirect_to admin_pricing_scheme_path(@pricing_scheme), notice: "Asignación de canchas actualizada correctamente."
    end

    private

    def set_pricing_scheme
      @pricing_scheme = PricingScheme.find(params[:id])
    end

    def pricing_scheme_params
      params.require(:pricing_scheme).permit(:name, :description)
    end
  end
end
