class CreateInstructions < ActiveRecord::Migration
  def change
    create_table :instructions do |t|
      t.boolean :has_image
      t.string :cover
      t.string :date
      t.string :name
      t.string :description
      t.string :who

      t.timestamps
    end
  end
end