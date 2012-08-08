class Venue
  include ActiveModel::Validations
  include ApplicationHelper
  attr_accessor :name, :result, :beers, :id, :spell_check, :search
  validates :name, presence: true
  
  def initialize venue_search, venue_id, mechanize_object
    @browser = mechanize_object
    @search = venue_search
    @id = venue_id
    @result = {name: "Searched for #{@search}"}
    @beers = []
  end
  
  def spell_check
    if @spell_check.nil?
      search_result = @browser.get("http://www.google.com/search?q=#{@search + ' bar'}")
      correction_link = search_result.links.select { |link| link.uri.to_s =~ /spell=1/ }.first
      @spell_check = correction_link.to_s.split[0..-2].join(' ') if correction_link
    else
      @spell_check
    end
  end

  # def search_beer_menus
  #   query = @spell_check || @search
  #   page = @browser.get("http://www.beermenus.com/search?q=#{@name}")
  #   venue_links = page.links.select {|link| link.uri.to_s =~ /places\/\d+/}
  #   if (page.body =~ /Oops/) || (venue_links.empty?)
  #     @result.merge!({beer_menus: "Venue is not on beermenus.com :("})
  #   else
  #     venue_page = venue_links.first.click
  #     @result.merge!({beer_menus: "#{venue_page.title.gsub('Beer Menu - ', '')}"})
  #     @beers = venue_page.links.select { |link| link.uri.to_s =~ /beers\/.+/}.map do |beer_link|
  #       Beer.new(beer_link.to_s, nil, @browser)
  #     end
  #     @beers.each { |beer| beer.search_untappd }
  #   end
  # end
  
  def search_untappd
    query = @spell_check || @search
    page = @browser.get("http://untappd.com/search?q=#{query}&type=venues")
    if (page.body =~ /No results/)
      @result.merge!({untappd: "Venue is not on untappd.com :("})
    else
      beer_num = 0
      venue_page = page.links.select {|link| link.uri.to_s =~ /venue\/.+/}.first.click
      @name = venue_page.search('div.info-box').css('h2').text
      @result.merge!({untappd: "#{@name}"})
      venue_page.search("p.checkin").map do |checkin|
        if @beers.select {|beer| beer.name == checkin.css('a')[1].text}.empty?
          beer_num += 1
          beer_checked_into = Mechanize::Page::Link.new(checkin.css('a')[1], @browser, venue_page).click
          new_beer = Beer.new(beer_checked_into, beer_num, @browser)
          new_beer.search_untappd
          @beers << new_beer
        end
      end.compact
    end
  end
end