class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :reservations do |t|
      t.date :reservation_date
      t.time :start_time
      t.time :end_time
      t.decimal :total_price
      t.integer :status
      t.references :court, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
