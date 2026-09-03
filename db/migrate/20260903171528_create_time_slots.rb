class CreateTimeSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :time_slots do |t|
      t.integer :day_of_week
      t.time :start_time
      t.time :end_time
      t.decimal :price
      t.references :court, null: false, foreign_key: true

      t.timestamps
    end
  end
end
