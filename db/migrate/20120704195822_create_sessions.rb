class CreateSessions < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.timestamp :last_seen_at
      t.string :username
      t.string :password

      t.timestamps
    end
  end
end
