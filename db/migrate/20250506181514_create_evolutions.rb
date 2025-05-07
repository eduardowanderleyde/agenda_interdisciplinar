class CreateEvolutions < ActiveRecord::Migration[7.1]
  def change
    create_table :evolutions do |t|
      t.references :appointment, null: false, foreign_key: true
      t.text :content
      t.text :next_steps

      t.timestamps
    end
  end
end
