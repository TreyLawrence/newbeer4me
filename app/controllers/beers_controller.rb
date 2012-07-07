class BeersController < ApplicationController
  before_filter :get_session, only: [:index, :search]
  
  def index
    @debug_string << "Visiting index, creating new mechanize object\n"
    
    #If there is no cookie present, and the user submitted a form with username and password
    if !@user_cookie_present && params[:untappd_info]
      @debug_string << "Sign in form completed\n"
      
      #Check to see if the username and passwword were both filled out
      if params[:untappd_info][:username].empty? || params[:untappd_info][:password].empty?
        #If not, then flash an error
        flash[:error] = "Invalid Username/Password combination."
      else
        #Otherwise attempt to sign into untappd
        @debug_string << "Form values: username: #{params[:untappd_info][:username]} password: #{params[:untappd_info][:password]}\n"
        @session.username = params[:untappd_info][:username]
        @password = params[:untappd_info][:password]
        
        @sign_in_result = sign_in_to_untappd
        if !@sign_in_result
          flash.now[:error] = "Invalid Username/Password combination."
        else
          @session.save
          session[:name] = @session.username
          session[:password] = @password
          @user_cookie_present = true
        end
      end
    end
  end
  
  def search
    if @user_cookie_present && params[:search]
      @debug_string << "Searching for #{params[:search]}\n"
      beer = Beer.new(params[:search].chomp.strip, @browser)
      if beer.spell_check?
        render :text => "Spell Check" #beer.spelling_correction
      elsif beer.search_untappd
        render :text => "Check in"#beer.checked_in
      elsif beer.errors.include? "User not signed in"
        sing_in_to_untappd
        if beer.search_untappd
          render :text => "Check in" #beer.checked_in
        else
          render text: "Error" # beer.error
        end
      else
        render text:  "error" #beer.error
      end
     else
       render :text => "Error, no cookie"
     end
  end
  
  private
    def get_session
      #initialize debug string and mechanize object if they haven't already been created
      @browser = Mechanize.new unless @mechanize
      @debug_string = "" if @debug_string.nil?
      
      #Check for session cookie
      if session[:name].blank? || session[:password].blank?
        @debug_string << "Cookie doesn't exist\n"
        @user_cookie_present = false
        @session = Session.new
        @session.last_seen_at = Time.new
      else
        @debug_string << "Cookie exists\n"
        @user_cookie_present = true
        @session = Session.find_by_username(session[:name])
        @session.last_seen_at = Time.new
        @session.save
        @password = session[:password]
      end
    end
    
    def sign_in_to_untappd
      @debug_string << "Logging in, username: #{@session.username} password: #{@password}\n"
      #If not, then sign in
      
      page = @browser.post('http://untappd.com/login', {
        "username" => @session.username,
        "password" => @password
      })
      
      #Verify that the sign in was successful
      username_link = page.link_with(:text => /Profile/)
      if username_link.nil?
        @debug_string << "Unsuccessful login\n\n#{page.body}\n\n"
        false
        session[:name] = ""
        session[:password] = ""
        @session.destroy
      elsif !username_link.uri.path.include? @session.username
        @debug_string << "Logged into wrong user, logging out\n"
        #If incorrect username, sign out (hopefully this should never happen)
        page.link_with(:text => /Log Out/).click
        #And try to sign in again
        sign_in_to_untappd
      else
        @debug_string << "Successfully logged in\n"
        true
      end
    end
end
