class SessionsController < ApplicationController
  def new
  end
  
  def create
    if !(params[:untappd_info][:username].empty? && params[:untappd_info][:password].empty?)
      logger.info "Received username: #{params[:untappd_info][:username]}"
      logger.info "Received password: #{params[:untappd_info][:password]}"
      current_user.untappd_username = params[:untappd_info][:username]
      current_user.password = params[:untappd_info][:password]
      current_user.last_seen_at = Time.now
      logger.info 'Signing into untappd from SessionsController#create'
      if sign_in_to_untappd
        logger.info "Successful sign in, saving name into cookie and saving user to database"
        session[:name] = current_user.untappd_username
        current_user.save
        redirect_to root_path
        return
      else
        logger.info "Unable to sign user in"
      end
    end
    logger.info "Test"
    flash.now[:error] = 'Invalid email/password combination'
    render 'new'
  end
  
  def destroy
    sign_out
    render 'new'
  end
end
