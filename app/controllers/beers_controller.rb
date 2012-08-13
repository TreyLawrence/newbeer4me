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
    @foursquare = current_user.foursquare_token && current_user.foursquare_id
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
    shout = JSON.parse(params[:checkin])['shout']

    if shout =~ /beer/i
      foursquare_id = JSON.parse(params[:checkin])['user']['id'])
      current_user = User.find_by_foursquare_id(foursquare_id)
      venue_name = JSON.parse(params[:checkin])['venue']['name'])
      checkin_id = JSON.parse(params[:checkin])['id'])

      if current_user
        current_user.process_foursquare_checkin(venue_name, checkin_id)
      end
    end
    
    render nothing: true
  end
  
  def disable_foursquare
    current_user.foursquare_token = nil
    current_user.foursquare_id = nil
    current_user.save
    redirect_to 'settings'
  end

  private

    def client_secret
      ENV['FS_CLIENT_SECRET']
    end
    
    def client_id
      ENV['FS_CLIENT_ID']
    end
end
