class AddPaymentStatusToReservations < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :payment_status, :integer, default: 0, null: false
  end
end

