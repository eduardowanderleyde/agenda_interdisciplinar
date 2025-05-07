class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :professional, null: false, foreign_key: true
      t.datetime :start_time
      t.integer :duration
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
