Rails.application.config.middleware.use OmniAuth::Builder do
  provider :untappd, ENV['UNTAPPD_ID'], ENV['UNTAPPD_SECRET']
  provider :foursquare, ENV['FOURSQUARE_ID'], ENV['FOURSQUARE_SECRET']
end