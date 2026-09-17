class CreatePricingSchemes < ActiveRecord::Migration[8.1]
  def change
    create_table :pricing_schemes do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
  end
end
