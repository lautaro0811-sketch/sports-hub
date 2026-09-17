module Admin
  class PricingRulesController < BaseController
    before_action :set_pricing_scheme
    before_action :set_pricing_rule, only: %i[edit update destroy]

    def create
      days = params.dig(:pricing_rule, :days_of_week)
      start_time = params.dig(:pricing_rule, :start_time)
      end_time = params.dig(:pricing_rule, :end_time)
      multiplier = params.dig(:pricing_rule, :multiplier)

      result = @pricing_scheme.add_rules(
        days_of_week: days,
        start_time: start_time,
        end_time: end_time,
        multiplier: multiplier
      )

      if result[:success]
        redirect_to admin_pricing_scheme_path(@pricing_scheme), notice: "Se guardaron #{result[:count]} regla(s) tarifaria(s) correctamente."
      else
        flash.now[:alert] = "No se pudieron guardar las reglas: #{result[:errors].join(' | ')}"
        @rules_by_day = @pricing_scheme.rules_grouped_by_day
        @new_rule = @pricing_scheme.pricing_rules.build(
          start_time: start_time,
          end_time: end_time,
          multiplier: multiplier
        )
        @selected_days = Array(days).map(&:to_i)
        @all_courts = Court.includes(:sports_complex, :sport).order("sports_complexes.name", "courts.name")
        render "admin/pricing_schemes/show", status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @pricing_rule.update(single_rule_params)
        redirect_to admin_pricing_scheme_path(@pricing_scheme), notice: "Regla tarifaria actualizada correctamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @pricing_rule.destroy
      redirect_to admin_pricing_scheme_path(@pricing_scheme), notice: "Regla tarifaria eliminada."
    end

    private

    def set_pricing_scheme
      @pricing_scheme = PricingScheme.find(params[:pricing_scheme_id])
    end

    def set_pricing_rule
      @pricing_rule = @pricing_scheme.pricing_rules.find(params[:id])
    end

    def single_rule_params
      params.require(:pricing_rule).permit(:day_of_week, :start_time, :end_time, :multiplier)
    end
  end
end
