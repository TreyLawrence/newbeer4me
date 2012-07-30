module ApplicationHelper
  def sign_in_to_untappd
    page = browser.post('http://untappd.com/login', {
      "username" => current_user.untappd_username,
      "password" => current_user.password
    })

    #Verify that the sign in was successful
    username_link = page.link_with(:text => /Profile/)
    if username_link.nil?
      logger.debug "Sign-in to untappd unsuccessful"
      sign_out
      false
    elsif !username_link.uri.path.include? current_user.untappd_username
      #If incorrect username, sign out (hopefully this should never happen)
      page.link_with(:text => /Log Out/).click
      #And try to sign in again
      sign_in_to_untappd
    else
      true
    end
  end
  
  def browser
    @browser ||= Mechanize.new
  end
  
  def sign_in(user)
    cookies.permanent[:remember_token] = user.remember_token
    self.current_user = user
  end
  
  def signed_in?
    if current_user
      # load in password from cookie
      current_user.password = session[:password]
      page = browser.get('http://untappd.com/')
      if page.link_with(:text => /Profile/).nil?
        sign_in_to_untappd
      end
    else
      false
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
  
  def current_user?(user)
    user == current_user
  end
  
  def signed_in_user
    logger.debug "\nChecking to see if user signed in"
    unless signed_in?
      logger.debug "User not signed in"
      store_location
      redirect_to signin_path, notice: "Please sign in."
    end
  end
  
  def sign_out
    logger.debug "Logging out, deleting cookie name and password"
    self.current_user = nil
    session.delete(:name)
    session.delete(:password)
  end
  
  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end
  
  def store_location
    session[:return_to] = request.fullpath
  end
end
