class AddAvailableThisWeekToProfessionals < ActiveRecord::Migration[7.1]
  def up
    add_column :professionals, :available_this_week, :boolean, default: false
    Professional.where(available_this_week: nil).update_all(available_this_week: false)
  end

  def down
    remove_column :professionals, :available_this_week
  end
end
