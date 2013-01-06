class User < ActiveRecord::Base
  has_secure_password
  attr_accessible :name, :email, :password, :password_confirmation
  attr_accessible :foursquare_token, :last_seen_at, :untappd_token, :foursquare_id
  validates :untappd_username, presence: true, uniqueness: { case_sensitive: false }
  validates :password_digest, presence: true
  
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence:   true,
                    format:     { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }
  validates :password_confirmation, presence: true
  
  before_save { self.email.downcase! }
  before_save :create_remember_token

  def process_foursquare_checkin(venue, checkin_id)
    browser = Mechanize.new

    page = browser.post('https://untappd.com/login', {
      "username" => self.untappd_username,
      "password" => self.password
    })

    username_link = page.links.select { |link| link.to_s =~ /Profile/ rescue nil }
    if username_link
      venue = Venue.new(venue, 'foursquare_venue', browser)

      venue.search_untappd
      if venue.beers.count > 0
        venue.beers.each {|beer| p beer.name }
        new_beer_names = 'Try these: ' + venue.new_beers.map { |beer| beer.name}.join(', ')
      else
        new_beer_names = "No beers found for this venue :("
      end

      p new_beer_names

      page = browser.post('https://api.foursquare.com/v2/checkins/' +
                          "#{checkin_id}/reply" +
                          "?oauth_token=#{self.foursquare_token}" +
                          "&text=#{new_beer_names.gsub(' ', '%20')[0..160]}")
    end
  end
  handle_asynchronously :process_foursquare_checkin
  
  private
    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end
end