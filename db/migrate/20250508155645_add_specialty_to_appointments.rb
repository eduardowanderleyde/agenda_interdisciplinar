class AddSpecialtyToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_reference :appointments, :specialty, foreign_key: true, null: true
  end
end
