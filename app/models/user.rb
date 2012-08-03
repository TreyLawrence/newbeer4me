class User < ActiveRecord::Base
  attr_accessible :foursquare_token, :last_seen_at, :untappd_username, :foursquare_id
  validates :untappd_username, presence: true, uniqueness: { case_sensitive: false }
  validates :password_digest, presence: true
  
  def password
    @password ||= AES.decrypt(password_digest, ENV['UNTAPPD_KEY']) if password_digest
  end
  
  def password=(new_password)
    if new_password
      @password = new_password
      self.password_digest = AES.encrypt(new_password, ENV['UNTAPPD_KEY'])
    end
  end
end
