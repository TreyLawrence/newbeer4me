class Venue
  include ActiveModel::Validations
  include ApplicationHelper
  attr_accessor :name, :result, :beers, :id, :spell_check
  validates :name, presence: true
  
  def initialize venue_name, venue_id, mechanize_object
    @browser = mechanize_object
    @name = venue_name
    @id = venue_id
    @result = {name: "Searched for #{@name}"}
    @beers = []
  end
  
  def spell_check
    doc = Nokogiri::HTML(@browser.get("http://www.google.com/search?q=#{@search + ' bar'}").body)
    correction_link = doc.css('a').select { |link| link['href'].include? "spell=1" }.first
    @spell_check = correction_link.text.split[0..-2].join(' ') if correction_link
  end
  
  def search_beer_menus
    page = @browser.get("http://www.beermenus.com/search?q=#{@name}")
    venue_links = page.links.select {|link| link.uri.to_s =~ /places\/\d+/}
    if (page.body =~ /Oops/) || (venue_links.empty?)
      @result.merge!({beer_menus: "Venue is not on beermenus.com :("})
    else
      venue_page = venue_links.first.click
      @result.merge!({beer_menus: "#{venue_page.title.gsub('Beer Menu - ', '')}"})
      @beers = venue_page.links.select { |link| link.uri.to_s =~ /beers\/.+/}.map do |beer_link|
        Beer.new(beer_link.to_s, nil, @browser)
      end
      @beers.each { |beer| beer.search_untappd}
    end
  end
end