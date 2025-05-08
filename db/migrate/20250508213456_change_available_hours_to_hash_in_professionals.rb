class ChangeAvailableHoursToHashInProfessionals < ActiveRecord::Migration[7.1]
  def up
    # Altera o tipo para json (já é, mas garante)
    change_column :professionals, :available_hours, :json, using: 'available_hours::json'

    # Migra os dados existentes: array para hash { all_days: [...] }
    Professional.reset_column_information
    Professional.find_each do |prof|
      prof.update_column(:available_hours, { 'all_days' => prof.available_hours }) if prof.available_hours.is_a?(Array)
    end
  end

  def down
    # Reverte para array simples
    Professional.reset_column_information
    Professional.find_each do |prof|
      prof.update_column(:available_hours, prof.available_hours.values.flatten) if prof.available_hours.is_a?(Hash)
    end
    change_column :professionals, :available_hours, :json, using: 'available_hours::json'
  end
end
