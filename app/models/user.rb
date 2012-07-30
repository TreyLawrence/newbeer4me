class User < ActiveRecord::Base
  attr_accessible :foursquare_token, :last_seen_at, :untappd_username
  attr_accessor :password
  validates :untappd_username, presence: true
end