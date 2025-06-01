class AddAvailableHoursToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :available_hours, :json
  end
end
