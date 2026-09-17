class AddPricingSchemesToCourtsAndComplexes < ActiveRecord::Migration[8.1]
  def change
    add_reference :courts, :pricing_scheme, foreign_key: true, null: true
    add_reference :sports_complexes, :default_pricing_scheme, foreign_key: { to_table: :pricing_schemes }, null: true
  end
end
