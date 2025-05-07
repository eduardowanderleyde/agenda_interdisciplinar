class AddDefaultSessionDurationToProfessionals < ActiveRecord::Migration[7.1]
  def change
    add_column :professionals, :default_session_duration, :integer
  end
end
