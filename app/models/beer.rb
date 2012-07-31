class Beer
  include ActiveModel::Validations
  attr_accessor :search, :id, :spell_check, :name, :brewery, :had, :debug_string
  validates :search, presence: true
  
  def initialize beer_name, beer_id, mechanize_object
    @browser = mechanize_object
    @search = beer_name
    @id = beer_id
    @debug_string = ""
  end
  
  def spell_check
    doc = Nokogiri::HTML(@browser.get("http://www.google.com/search?q=#{@search + ' beer'}").body)
    correction_link = doc.css('a').select { |link| link['href'].include? "spell=1" }.first
    @spell_check = correction_link.text.split[0..-2].join(' ') if correction_link
  end
  
  def search_untappd
    query = @spell_check || @search
    
    url = "http://untappd.com/search?q=#{query}"
    debug_string << "Searching untappd: #{url}\n"

    page = @browser.get("http://untappd.com/search?q=#{query}")
    
    if page.links.select { |link| link.uri.to_s[/login/] rescue nil}.empty?
      debug_string << "Signed in to untappd\n"
      beer_links = page.links.select { |link| link.uri.to_s[/beer\/\d+/] rescue nil }
      link = beer_links.first
      if link
        doc = Nokogiri::HTML(link.click.body)
        @brewery = doc.css('a').select {|link| link['href'].include? "brewery" }.first.text
        @name = link.text
        if doc.css('.drank.tip').to_s.empty?
          @had = false
        else
          @had = true
        end
      end
      true
    else
      debug_string << "Not signed in to untappd\n"
      false
    end
  end
end