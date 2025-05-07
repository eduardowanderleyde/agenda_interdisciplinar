class CreatePatientSpecialties < ActiveRecord::Migration[7.1]
  def change
    create_table :patient_specialties do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :specialty, null: false, foreign_key: true
      t.text :notes

      t.timestamps
    end

    add_index :patient_specialties, %i[patient_id specialty_id], unique: true, name: 'index_patient_specialties_unique'
  end
end
