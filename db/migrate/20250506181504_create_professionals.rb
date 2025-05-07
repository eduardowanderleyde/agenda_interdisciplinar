class CreateProfessionals < ActiveRecord::Migration[7.1]
  def change
    create_table :professionals do |t|
      t.string :name
      t.string :specialty
      t.json :available_days
      t.json :available_hours

      t.timestamps
    end
  end
end
