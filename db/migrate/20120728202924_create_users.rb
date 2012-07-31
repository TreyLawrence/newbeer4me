class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :untappd_username
      t.datetime :last_seen_at
      t.string :foursquare_token
      t.string :foursquare_id

      t.timestamps
    end
  end
end
