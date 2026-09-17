class AddPriceMultiplierToTimeSlots < ActiveRecord::Migration[8.1]
  def change
    add_column :time_slots, :price_multiplier, :decimal, precision: 4, scale: 2, default: 1.0, null: false
  end
end