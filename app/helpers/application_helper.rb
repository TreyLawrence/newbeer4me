module ApplicationHelper
  def sign_in_to_untappd
    page = browser.post('http://untappd.com/login', {
      "username" => current_user.untappd_username,
      "password" => current_user.password
    })

    #Verify that the sign in was successful
    username_link = page.links.select { |link| link.to_s =~ /Profile/ rescue nil }
    if username_link.nil?
      logger.debug "Sign-in to untappd unsuccessful"
      sign_out
      false
    else
      true
    end
  end
  
  def browser
    @browser ||= Mechanize.new
  end
  
  def signed_in?
    if session[:password].nil? || session[:password].empty?
      false
    else
      current_user.password = session[:password]
      page = browser.get('http://untappd.com/')
      if page.link_with(:text => /Profile/).nil?
        sign_in_to_untappd
      end
    end
  end
  
  def current_user=(user)
    @current_user = user
  end
  
  def current_user
    if @current_user.nil?
      @current_user = User.find_by_untappd_username(session[:name])
      if @current_user.nil?
        logger.debug "Couldn't find current user in database, creating new one"
        @current_user = User.new
      else
        logger.debug "Found current user in database"
      end
    end
    @current_user
  end
  
  def signed_in_user
    unless signed_in?
      render 'sessions/new', notice: "Please sign in."
    end
  end
  
  def sign_out
    logger.debug "Logging out, deleting cookie name and password"
    self.current_user = nil
    session.delete(:name)
    session.delete(:password)
  end
  
  def store_location
    session[:return_to] = request.fullpath
  end
end
