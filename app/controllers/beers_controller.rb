class BeersController < ApplicationController
  before_filter :signed_in_user, only: [:index, :search, :settings, :destroy]
  
  def index
  end
  
  def search
    if params[:search]
      if params[:type] == "beer"
        beer = Beer.new(params[:search].strip, params[:id], browser)
        beer.spell_check
        if beer.search_untappd
          render text: {result: render_to_string(beer), id: params[:id], type: params[:type]}.to_json
        else
          render text: {result: "Error logging in", id: params[:id], type: params[:type]}.to_json
        end
      elsif params[:type] == "venue"
        venue = Venue.new(params[:search].strip, params[:id], browser, logger)
        venue.spell_check
        venue.search_untappd
        render text: {result: render_to_string(venue), id: params[:id], type: params[:type]}.to_json
      end
    else
      render text: {result: "No cookie", id: params[:id], type: params[:type]}.to_json
    end
  end

  def settings
    @foursquare = current_user.foursquare_token
    if params[:error]
      current_user.foursquare_token = nil
      current_user.foursquare_id = nil
      current_user.save
    elsif params[:code]
      begin
        page = browser.get('https://foursquare.com/oauth2/access_token' + 
                          "?client_id=#{client_id}" + 
                          "&client_secret=#{client_secret}" + 
                          "&grant_type=authorization_code" + 
                          '&redirect_uri=https://newbeer4me.herokuapp.com/settings' + 
                          "&code=#{params['code']}")

        current_user.foursquare_token = JSON.parse(page.body)['access_token']

        page = browser.get('https://api.foursquare.com/v2/users/self' + 
                          "?oauth_token=#{current_user.foursquare_token}")

        current_user.foursquare_id = JSON.parse(page.body)["response"]["user"]["id"]

        if current_user.foursquare_id && current_user.foursquare_token
          current_user.save
        end
        redirect_to settings_path
      rescue Mechanize::Error => e
        logger.info e
      end
    end
  end
  
  def checkin
    render nothing: true
    
    begin
      current_user = User.find_by_foursquare_id(JSON.parse(params[:checkin])['user']['id'])
      logger.info "Current user is #{current_user.untappd_username || 'nil' }"
      logger.info "Password is #{current_user.password || 'nil'}"
      logger.info "Signing in from inside checkin"
    
      shout = JSON.parse(params[:checkin])['shout']
      logger.info ("Shout is #{JSON.parse(params[:checkin])['shout']}")
    
      logger.info "Venue name is #{JSON.parse(params[:checkin])['venue']['name'] || 'nil'}"
      venue = Venue.new(JSON.parse(params[:checkin])['venue']['name'], 1, browser, logger)

      if shout =~ /beer/i    
        if current_user && sign_in_to_untappd
          venue.search_untappd
          if venue.beers.count > 0
            venue.beers.each {|beer| logger.info beer.name }

            new_beer_names = 'Try these: ' + venue.new_beers.map { |beer| beer.name}.join(', ')
          else
            new_beer_names = "No beers found for this venue :("
          end

          url = 'https://api.foursquare.com/v2/checkins/' + 
                "#{current_user.foursquare_id}/reply" + 
                "?oauth_token=#{current_user.foursquare_token}" +
                "&text=#{new_beer_names.gsub(' ', '%20')[0..160]}"

          logger.info "url: #{url}"

          page = browser.post('https://api.foursquare.com/v2/checkins/' + 
                              "#{current_user.foursquare_id}/reply" + 
                              "?oauth_token=#{current_user.foursquare_token}" +
                              "&text=#{new_beer_names.gsub(' ', '%20')[0..160]}")
        else
          logger.info "Unsuccessful :("
        end
      end
    rescue Exception => e  
      logger.info e.message  
      logger.info e.backtrace.inspect  
    end
  end
  
  def disable_foursquare
    current_user.foursquare_token = nil
    current_user.foursquare_id = nil
    render 'settings'
  end

  private
    
    def client_secret
      ENV['FS_CLIENT_SECRET']
    end
    
    def client_id
      ENV['FS_CLIENT_ID']
    end
end
