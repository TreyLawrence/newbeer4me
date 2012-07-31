class BeersController < ApplicationController
  before_filter :signed_in_user, only: [:index, :search, :settings, :destroy]
  
  def index
  end
  
  def search
    if params[:search]
      if params[:type] == "beer"
        beer = Beer.new(params[:search].strip, params[:id], @browser)
        beer.spell_check?
        if beer.search_untappd
          render text: {result: render_to_string(beer), id: params[:id], type: params[:type]}.to_json
        else
          render text: {result: "Error logging in", id: params[:id], type: params[:type]}.to_json
        end
      else
        venue = Venue.new(params[:search].strip, params[:id], @browser)
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
    @test = params
    logger.info "We received a checkin!!!!!!!!!!?????????!!!!!!!!!!"
    logger.info "User id = #{JSON.parse(params[:checkin])['user']['id']}"
    current_user = User.find_by_foursquare_id(JSON.parse(params[:checkin])['user']['id'])
    logger.info "Current user = #{current_user ? current_user : 'nil'}"
    url = 'https://api.foursquare.com/v2/checkins/' + 
          "#{JSON.parse(params[:checkin])['id']}/reply" + 
          "?oauth_token=#{current_user.foursquare_token}" +
          "&text=#{"Nice check-in bitch-face ass-car".gsub(" ", "%20")}"

    logger.info "url = #{url ? url : "nil"}"
    logger.info "username = #{current_user.untappd_username ? current_user.untappd_username : 'nil'}"
    logger.info "password = #{current_user.password ? current_user.password : 'nil'}"
    logger.info "foursquare = #{current_user.foursquare_token ? current_user.foursquare_token : 'nil'}"
                        
    page = browser.post('https://api.foursquare.com/v2/checkins/' + 
                        "#{JSON.parse(params[:checkin])['id']}/reply" + 
                        "?oauth_token=#{current_user.foursquare_token}" +
                        "&text=#{"Nice check-in bitzch-face azs-car".gsub(" ", "%20")}")
    logger.info "page = #{page unless page.nil?}"
  end
  
  def disable_foursquare
    current_user.foursquare_token = nil
  end
  
  def destroy
    @debug_string << "Deleting session\n"
    session[:password] = ""
    session[:name] = ""
    @session.destroy
    @session = nil
    @password = ""
    @user_signed_in = false
    redirect_to root_path
  end

  private
    
    def client_secret
      "SDXVH1EYDJJHJPLJPNN0JJGIMZLQZTFSXNRH1MHKR3SLPRR0"
    end
    
    def client_id
      "DLTI5SNFPYNXCV4AKZYYPZWXOFWLS3B2ZBGOWEC1DB1NO3BJ"
    end
end
