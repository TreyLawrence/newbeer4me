class Users < ActiveRecord::Migration
  def change
    add_index :users, :email, unique: true
    add_index :users, :remember_token, unique: true
  end
end
