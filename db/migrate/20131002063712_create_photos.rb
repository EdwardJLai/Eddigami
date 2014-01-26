class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.string :caption
      t.string :incidentName
      t.string :operationalPeriod
      t.string :teamNumber
      t.string :contentType
      t.string :filename
    	t.string :image
    	t.boolean :edited
    	t.decimal :lat
    	t.decimal :lng

      t.timestamps
    end
  end
end
