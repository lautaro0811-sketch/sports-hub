class CreatePricingRules < ActiveRecord::Migration[8.1]
  def change
    create_table :pricing_rules do |t|
      t.references :pricing_scheme, null: false, foreign_key: { on_delete: :cascade }
      t.integer :day_of_week, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.decimal :multiplier, precision: 4, scale: 2, default: 1.0, null: false

      t.timestamps
    end

    add_index :pricing_rules, [:pricing_scheme_id, :day_of_week]
  end
end

