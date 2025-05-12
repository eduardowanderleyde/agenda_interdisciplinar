class ChangeDefaultAvailableThisWeekInPatients < ActiveRecord::Migration[7.1]
  def up
    change_column_default :patients, :available_this_week, false
    Patient.where(available_this_week: nil).update_all(available_this_week: false)
  end

  def down
    change_column_default :patients, :available_this_week, nil
  end
end
