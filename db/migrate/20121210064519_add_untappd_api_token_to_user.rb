class AddUntappdApiTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :untappd_token, :string
    add_column :users, :email, :string
    add_column :users, :name, :string
  end
end
