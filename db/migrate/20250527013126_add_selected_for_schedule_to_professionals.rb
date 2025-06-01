class AddSelectedForScheduleToProfessionals < ActiveRecord::Migration[7.1]
  def change
    add_column :professionals, :selected_for_schedule, :boolean
  end
end
