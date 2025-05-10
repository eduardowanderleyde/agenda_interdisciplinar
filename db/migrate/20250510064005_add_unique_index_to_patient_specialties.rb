class AddUniqueIndexToPatientSpecialties < ActiveRecord::Migration[7.1]
  def change
    remove_index :patient_specialties, column: %i[patient_id specialty_id] if index_exists?(:patient_specialties,
                                                                                            %i[patient_id specialty_id])
    add_index :patient_specialties, %i[patient_id specialty_id], unique: true, name: 'index_patient_specialties_unique'
  end
end
