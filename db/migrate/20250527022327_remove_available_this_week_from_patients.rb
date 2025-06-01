class RemoveAvailableThisWeekFromPatients < ActiveRecord::Migration[7.1]
  def change
    remove_column :patients, :available_this_week, :boolean
  end
end
