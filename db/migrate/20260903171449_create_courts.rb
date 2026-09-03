class CreateCourts < ActiveRecord::Migration[8.1]
  def change
    create_table :courts do |t|
      t.string :name
      t.string :surface_type
      t.boolean :is_active
      t.references :sports_complex, null: false, foreign_key: true
      t.references :sport, null: false, foreign_key: true

      t.timestamps
    end
  end
end
