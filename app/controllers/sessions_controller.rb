class SessionsController < ApplicationController
  def new
  end
  
  def create
    logger.debug "PARAMSBICHES!!!!!!!!!#{params}"
    if !(params[:untappd_info][:username].empty? && params[:untappd_info][:password].empty?)
      current_user.untappd_username = params[:untappd_info][:username]
      current_user.password = params[:untappd_info][:password]
      current_user.last_seen_at = Time.now
      if sign_in_to_untappd
        logger.debug "Successfully signed into untappd, save user and redirect to root path"
        session[:name] = current_user.untappd_username
        session[:password] = current_user.password
        current_user.save
        render 'beers/index'
        return
      else
        logger.debug "Unable to sign user in"
      end
    end
    logger.debug "Test"
    flash.now[:error] = 'Invalid email/password combination'
    render 'new'
  end
  
  def destroy
    sign_out
    render 'new'
  end
end
