class Beer
  include ActiveModel::Validations
  attr_accessor :search, :id, :spell_check, :name, :brewery, :had, :debug_string, :avg_rating, :my_rating
  validates :search, presence: true
  
  def initialize beer, beer_id, mechanize_object
    if beer.class == String
      @search = beer
    elsif beer.class == Mechanize::Page
      @beer_page = beer
    else
      raise "Need beer as String or Mechanize::Page"
    end

    @browser = mechanize_object
    @id = beer_id
    @debug_string = ""
  end
  
  def spell_check
    if @spell_check.nil?
      search_result = @browser.get("http://www.google.com/search?q=#{@search + ' beer'}")
      correction_link = search_result.links.select { |link| link.uri.to_s =~ /spell=1/ }.first
      @spell_check = correction_link.to_s.split[0..-2].join(' ') if correction_link
    else
      @spell_check
    end
  end

  def search_untappd
    if @search.nil?
      beer_page = @beer_page
    else
      query = @spell_check || @search
      query_page = @browser.get("http://untappd.com/search?q=#{query}")
      beer_links = query_page.links.select { |link| link.uri.to_s[/beer\/\d+/] rescue nil }
      beer_page = beer_links.first.click unless beer_links.empty?
    end
    
    if beer_page.links.select { |link| link.uri.to_s[/login/] rescue nil}.empty?
      @brewery = beer_page.search("ul.beer-details").css('a').text
      @name = beer_page.search("ul.beer-details").css('h2').text
      @had = !beer_page.search('.drank.tip').empty?
      @avg_rating = beer_page.search('ul.rating-display').css('span')[1].text.strip
      true
    else
      false
    end
  end
end