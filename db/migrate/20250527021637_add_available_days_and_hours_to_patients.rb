class AddAvailableDaysAndHoursToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :available_days, :json
  end
end
