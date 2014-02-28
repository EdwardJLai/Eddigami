class AddDescriptionsToInstructions < ActiveRecord::Migration
  def change
    add_column :instructions, :description, :string
    add_column :instructions, :name, :string
  end
end
