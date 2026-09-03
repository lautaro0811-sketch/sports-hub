class CreateSportsComplexes < ActiveRecord::Migration[8.1]
  def change
    create_table :sports_complexes do |t|
      t.string :name
      t.string :address
      t.string :city
      t.string :phone

      t.timestamps
    end
  end
end
