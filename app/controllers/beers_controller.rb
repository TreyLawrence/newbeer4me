class BeersController < ApplicationController
  before_filter :get_session, only: [:index, :search]
  
  def index
    @debug_string << "Visiting index\n"
    @browser = Mechanize.new
    
    if !@user_cookie_present && params[:untappd_info]
      @debug_string << "Sign in form completed\n"
      if params[:untappd_info][:username].empty? || params[:untappd_info][:password].empty?
        flash[:error] = "Invalid Username/Password combination."
      else
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
      @input_beers.merge! = params[:search].chomp.strip
      @results = @input_beers.each do |beer|
        search_untappd spell_check beer
      end
    end
  end
  
  private
    def get_session
      @debug_string = "" if @debug_string.nil?
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
    
    def search_untappd beer
      # Visit each beer page and check to see if it's been checked in yet
      @debug_string << "Searching Untappd for #{beer.split('+').join(' ')}\n"
      page = @browser.get("http://untappd.com/search?q=#{beer}")
      
      if page.uri.path.include? "login"
        sign_in_to_untappd
      end
      
      beer_links = page.links.select { |link| link.uri.to_s[/beer\/\d+/] }
      # beer_links.each do |link|
      link = beer_links[0]
      if link.nil?
        @debug_string << "Search has no results\n"
        [beer,nil]
      else
        if Nokogiri::HTML(link.click.body).css('.drank.tip').to_s.empty?
          @debug_string << "You have had #{link.to_s} before\n"
          [link.to_s,true]
        else
          @debug_string << "You have not had this beer before\n"
          [link.to_s,false]
        end
      end
    end
end
