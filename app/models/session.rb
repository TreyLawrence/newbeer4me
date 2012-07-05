class Session < ActiveRecord::Base
  attr_accessible :username, :last_seen_at, :password
end
