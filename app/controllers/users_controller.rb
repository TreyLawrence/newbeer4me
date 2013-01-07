class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      sign_in @user
      flash[:success] = "Welcome to NewBeer4Me!"
      redirect_to root_path
    else
      render 'new'
    end
  end

  def settings
    @foursquare = current_user.foursquare_token && current_user.foursquare_id
    @untappd = current_user.untappd_token && current_user.untappd_id
  end

  def connect_untappd
    if params[:code]
      begin
        oauth_json = JSON.parse(browser.get("http://untappd.com/oauth/authorize/" +
                          "?client_id=#{untappd_client_id}" +
                          "&client_secret=#{untappd_client_secret}" +
                          "&response_type=code" +
                          "&redirect_url=https://newbeer4me.herokuapp.com/connect/untappd" +
                          "&code=#{params[:code]}").body)
                          
        logger.info oauth_json
        
        current_user = User.new if !signed_in?
        current_user.untappd_token = oauth_json['response']['access_token']
        
        logger.info "access_token #{oauth_json['response']['access_token']}"
        logger.info "current_user #{current_user}"
        
        user_json = JSON.parse(browser.get("http://api.untappd.com/v4/user/info" +
                          "?access_token=#{current_user.untappd_token}").body)
        
        current_user.first_name |= user_json["response"]["user"]["first_name"]
        current_user.last_name |= user_json["response"]["user"]["last_name"]
        
        current_user.save if current_user.untappd_token
      rescue Mechanize::Error => e
        logger.info e
      end
    end
    redirect_to root_path
  end

  def disable_untappd
    current_user.untappd_token = nil
    current_user.save
    redirect_to settings_path
  end

  def connect_foursquare
    if params[:code]
      begin
        logger.info 'https://foursquare.com/oauth2/access_token' +
                          "?client_id=#{foursquare_client_id}" +
                          "&client_secret=#{foursquare_client_secret}" +
                          "&grant_type=authorization_code" +
                          '&redirect_uri=https://newbeer4me.herokuapp.com/connect/foursquare' +
                          "&code=#{params['code']}"
        oauth_json = JSON.parse(browser.get('https://foursquare.com/oauth2/access_token' +
                          "?client_id=#{foursquare_client_id}" +
                          "&client_secret=#{foursquare_client_secret}" +
                          "&grant_type=authorization_code" +
                          '&redirect_uri=https://newbeer4me.herokuapp.com/connect/foursquare' +
                          "&code=#{params['code']}").body)
                          
        current_user = User.new if !signed_in?
        current_user.foursquare_token = oauth_json['access_token']

        user_json = JSON.parse(browser.get('https://api.foursquare.com/v2/users/self' +
                          "?oauth_token=#{current_user.foursquare_token}").body)

        current_user.foursquare_id = user_json["response"]["user"]["id"]

        if current_user.foursquare_id && current_user.foursquare_token
          current_user.save
        end
      rescue Mechanize::Error => e
        logger.info e
      end
    end
    redirect_to root_path
  end

  def disable_foursquare
    current_user.foursquare_token = nil
    current_user.foursquare_id = nil
    current_user.save
    redirect_to settings_path
  end

  private

    def untappd_client_secret
      ENV['UNTAPPD_CLIENT_SECRET']
    end

    def untappd_client_id
      ENV['UNTAPPD_CLIENT_ID']
    end

    def foursquare_client_secret
      ENV['FS_CLIENT_SECRET']
    end

    def foursquare_client_id
      ENV['FS_CLIENT_ID']
    end
end
