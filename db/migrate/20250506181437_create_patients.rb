class CreatePatients < ActiveRecord::Migration[7.1]
  def change
    create_table :patients do |t|
      t.string :name
      t.date :birthdate
      t.string :diagnosis
      t.text :observations

      t.timestamps
    end
  end
end
