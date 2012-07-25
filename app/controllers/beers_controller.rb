class BeersController < ApplicationController
  before_filter :get_session, only: [:index, :search, :settings]
  
  def index
    #If there is no cookie present, and the user submitted a form with username and password
    if !@user_signed_in && params[:untappd_info]
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
          @user_signed_in = true
        end
      end
    end
  end
  
  def search
    if @user_signed_in && params[:search]
      @debug_string << "Searching for #{params[:search]}\n"
      beer = Beer.new(params[:search].chomp.strip, @browser)
      beer.spell_check?
      if !beer.search_untappd
        sign_in_to_untappd
        if !beer.search_untappd
          render text: {result: "<li class='beers'>Error logging in</li>", id: params[:id]}.to_json
        end
      end
      render text: {result: render_to_string(beer), id: params[:id]}.to_json
    else
      render text: {result: "<li class='beers'>No cookie</li>", id: params[:id]}.to_json
    end
  end
  
  def settings
    
  end
  
  private
    def get_session
      #initialize debug string and mechanize object if they haven't already been created
      @browser ||= Mechanize.new
      @debug_string ||= ""
      
      #Check for session cookie
      @debug_string = "" if @debug_string.nil?
      if session[:name].blank? || session[:password].blank?
        @debug_string << "Cookie doesn't exist\n"
        @user_signed_in = false
        @session = Session.new
        @session.last_seen_at = Time.new
      else
        @debug_string << "Cookie exists\n"
        @user_signed_in = true
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
