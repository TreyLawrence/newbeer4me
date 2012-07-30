class User < ActiveRecord::Base
  attr_accessible :last_seen_at, :untappd_username, :token
  validates :untappd_username, presence: true
end
