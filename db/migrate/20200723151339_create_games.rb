class CreateGames < ActiveRecord::Migration[6.0]
  def change
    create_table :games do |t|
      t.string :online_id
      t.integer :timeout

      t.timestamps
    end
  end
end
