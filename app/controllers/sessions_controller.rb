class SessionsController < ApplicationController
  def new
    logger.debug 'Inside SessionsController#new'
  end
  
  def create
    logger.debug 'Inside SessionsController#create'
    if (params[:untappd_info][:username] && params[:untappd_info][:password])
      logger.debug 'Username and password exist inside form'
      user = current_user
      user.untappd_username = params[:untappd_info][:username]
      user.password = params[:untappd_info][:password]
      user.last_seen_at = Time.now
      if sign_in_to_untappd
        logger.debug "Successfully signed into untappd, save user and redirect to root path"
        session[:name] = user.untappd_username
        session[:password] = user.password
        user.save
        redirect_to root_path
        return
      else
        logger.debug "Unable to sign into untappd"
      end
    end
    flash.now[:error] = 'Invalid email/password combination'
    render 'new'
  end
  
  def destroy
    sign_out
    redirect_to root_path
  end
end
