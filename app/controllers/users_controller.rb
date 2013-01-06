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
    if params[:error]
      current_user.foursquare_token = nil
      current_user.foursquare_id = nil
      current_user.save
    elsif params[:code]
      begin
        oauth_json = browser.get("http://untappd.com/oauth/authorize/" +
                           "?client_id=#{untappd_client_id}" +
                           "&client_secret=#{untappd_client_secret}" +
                           "&response_type=code" +
                           "&redirect_url=https://newbeer4me.herokuapp.com/connect/untappd" +
                           "&code=#{params[:code]}")

        current_user.untappd_token = JSON.parse(oauth_json.body)['access_token']

        page = browser.get('http://untappd.com/v4/user/info' +
                          "?access_token=#{current_user.untappd_token}")

        current_user.untappd_id = JSON.parse(page.body)["response"]["user"]["id"]

        if current_user.foursquare_id && current_user.foursquare_token
          current_user.save
        end
      rescue Mechanize::Error => e
        logger.info e
      end
    end
  end

  def disable_untappd
    current_user.untappd_token = nil
    current_user.untappd_id = nil
    current_user.save
    redirect_to settings_path
  end

  def connect_foursquare
    if params[:error]
      current_user.foursquare_token = nil
      current_user.foursquare_id = nil
      current_user.save
    elsif params[:code]
      begin
        page = browser.get('https://foursquare.com/oauth2/access_token' +
                          "?client_id=#{foursquare_client_id}" +
                          "&client_secret=#{foursquare_client_secret}" +
                          "&grant_type=authorization_code" +
                          '&redirect_uri=https://newbeer4me.herokuapp.com/connect/foursquare' +
                          "&code=#{params['code']}")

        current_user.foursquare_token = JSON.parse(page.body)['access_token']

        page = browser.get('https://api.foursquare.com/v2/users/self' +
                          "?oauth_token=#{current_user.foursquare_token}")

        current_user.foursquare_id = JSON.parse(page.body)["response"]["user"]["id"]

        if current_user.foursquare_id && current_user.foursquare_token
          current_user.save
        end
      rescue Mechanize::Error => e
        logger.info e
      end
    end
  end

  def disable_foursquare
    current_user.foursquare_token = nil
    current_user.foursquare_id = nil
    current_user.save
    redirect_to settings_path
  end

  private

    def untappd_client_secret
      ENV['UNT_CLIENT_SECRET']
    end

    def untappd_client_id
      ENV['UNT_CLIENT_ID']
    end

    def foursquare_client_secret
      ENV['FS_CLIENT_SECRET']
    end

    def foursquare_client_id
      ENV['FS_CLIENT_ID']
    end
end