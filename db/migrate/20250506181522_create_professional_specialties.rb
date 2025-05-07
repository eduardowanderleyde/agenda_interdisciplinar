class CreateProfessionalSpecialties < ActiveRecord::Migration[7.1]
  def change
    create_table :professional_specialties do |t|
      t.references :professional, null: false, foreign_key: true
      t.references :specialty, null: false, foreign_key: true

      t.timestamps
    end

    add_index :professional_specialties, %i[professional_id specialty_id], unique: true,
                                                                           name: 'index_professional_specialties_unique'
  end
end
