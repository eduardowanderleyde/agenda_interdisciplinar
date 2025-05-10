class AddDefaultDurationToSpecialties < ActiveRecord::Migration[7.1]
  def change
    add_column :specialties, :default_duration, :integer, default: 45, null: false
  end
end
