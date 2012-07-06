class Session < ActiveRecord::Base
  attr_accessible :last_seen_at, :username
  validates :username, presence: true
end
