class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.string :caption
      t.string :incident_name
      t.string :operational_period
      t.string :team_number
      t.string :taken_by
      t.string :time_taken
    	t.string :image
    	t.boolean :edited
    	t.decimal :lat
    	t.decimal :lng
    	t.integer :rotation
    	t.references :instructions
    	
      t.timestamps
    end
  end
end
