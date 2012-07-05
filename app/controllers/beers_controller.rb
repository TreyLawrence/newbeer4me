class BeersController < ApplicationController
  before_filter :get_session, only: [:index]
  
  def index
    untappd_user = params[:untappd_info]
    search_beers = params[:search]
    @browser = Mechanize.new
    
    if !@user_signed_in && !untappd_user.nil? && !untappd_user["username"].nil? && !untappd_user["password"].nil?
      @session.username = untappd_user["username"]
      @session.password = untappd_user["password"]
      @session.save
      session[:name] = @session.username
      @user_signed_in = true
    elsif @user_signed_in && !search_beers.nil? && !search_beers[:beers].nil?
      @input_beers = search_beers[:beers].chomp.strip.split(',').map { |beer| beer.strip }
      @spell_checked = spell_check_beers
      sign_in_to_untappd
      @results = search_untappd
    end
  end
  
  private
    def get_session
      if session[:name].blank?
        @user_signed_in = false
        @session = Session.create
        @session.last_seen_at = Time.new
      else
        @user_signed_in = true
        @session = Session.find_by_username(session[:name])
        @session.last_seen_at = Time.new
        @session.save
      end
    end
    
    def sign_in_to_untappd
      page = @browser.post('http://untappd.com/login', {
        "username" => @session.username,
        "password" => @session.password
      })
    end
    
    def spell_check_beers
      @input_beers.map do |beer|
        beer = beer.split.join('+')
        doc = Nokogiri::HTML(@browser.get("http://www.google.com/search?q=#{beer}").body)
        spelling_correction = doc.css('a').select { |link| link['href'].include? "spell=1" }.first
        if !spelling_correction.nil?
          beer = spelling_correction.text.split.join('+')
        end
      end
    end
    
    def search_untappd
      # Visit each beer page and check to see if it's been checked in yet
      Hash[@spell_checked.map do |beer|
        page = @browser.get("http://untappd.com/search?q=#{beer}")
        beer_links = page.links.select { |link| link.uri.to_s[/beer\/\d+/] }
        # beer_links.each do |link|
        link = beer_links[0]
        if link.nil?
          [beer,nil]
        else
          puts "The first result is #{link.to_s}"
          if Nokogiri::HTML(link.click.body).css('.drank.tip').to_s.empty?
            [beer,true]
          else
            [beer,false]
          end
        end
      end]
    end
end
