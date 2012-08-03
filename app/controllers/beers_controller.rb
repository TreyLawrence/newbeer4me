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
      else
        venue = Venue.new(params[:search].strip, params[:id], browser)
        venue.spell_check
        venue.search_beer_menus
        render text: {result: render_to_string(venue), id: params[:id], type: params[:type]}.to_json
      end
    else
      render text: {result: "No cookie", id: params[:id], type: params[:type]}.to_json
    end
  end

  def settings
    if params[:error]
      current_user.foursquare_token = nil
      current_user.foursquare_id = nil
      current_user.save
    elsif params[:code]
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
    end
    @foursquare = !!current_user.foursquare_token
  end
  
  def checkin
    render nothing: true
    current_user = User.find_by_foursquare_id(JSON.parse(params[:checkin])['user']['id'])
    logger.info "Current user is #{current_user}"
    shout = JSON.parse(params[:checkin])['shout']
    logger.info ("Shout is #{JSON.parse(params[:checkin])['shout']}")
    if current_user && (shout =~ /beer/i)
      logger.info "Venue name is #{JSON.parse(params[:checkin])['venue']['name'] ? JSON.parse(params[:checkin])['venue']['name'] : 'nil'}"
      venue = Venue.new(JSON.parse(params[:checkin])['venue']['name'], 1, browser)
      venue.search_beer_menus
      if venue.beers.count > 0
        venue.beers.each {|beer| logger.info "beers #{beer.name}" }
        new_beer_names = 'Try these: ' + venue.beers.select { |beer| !beer.had}.map { |new_beer| new_beer.name}.join(' ')
      else
        new_beer_names = "This bar isn't on beermenus, bro :("
      end
      
      url = 'https://api.foursquare.com/v2/checkins/' + 
            "#{JSON.parse(params[:checkin])['id']}/reply" + 
            "?oauth_token=#{current_user.foursquare_token}" +
            "&text=#{new_beer_names.gsub(' ', '%20')[0..160]}"

      logger.info url
      
      begin
        page = browser.post('https://api.foursquare.com/v2/checkins/' + 
                            "#{JSON.parse(params[:checkin])['id']}/reply" + 
                            "?oauth_token=#{current_user.foursquare_token}" +
                            "&text=#{new_beer_names.gsub(' ', '%20')[0..160]}")
      rescue Mechanize::Error => e
        logger.info e
      end
    end
  end
  
  def disable_foursquare
    current_user.foursquare_token = nil
  end

  private
    
    def client_secret
      ENV['FS_CLIENT_SECRET']
    end
    
    def client_id
      ENV['FS_CLIENT_ID']
    end
end
