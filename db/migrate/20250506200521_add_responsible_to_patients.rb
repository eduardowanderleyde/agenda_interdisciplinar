class AddResponsibleToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :responsible, :string
  end
end
