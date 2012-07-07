class Beer
  include ActiveModel::Validations
  attr_accessor :name, :result
  validates :name, presence: true
  
  def initialize beer_name, mechanize_object
    @errors = ""
    @browser = mechanize_object
    @name = beer_name
    @result = {}
  end
  
  def spell_check?
    doc = Nokogiri::HTML(@browser.get("http://www.google.com/search?q=#{@name + ' beer'}").body)
    correction_link = doc.css('a').select { |link| link['href'].include? "spell=1" }.first
    if correction_link.nil?
      false
    else
      result.merge!({spell_check: correction_link.text.split[0..-2].join(' ')})
      true
    end
  end
  
  def search_untappd
    query = (result[:spell_check]) ? result[:spell_check] : @name
    page = @browser.get("http://untappd.com/search?q=#{query}")
    
    if page.links.select { |link| link.uri.to_s[/login/]}.empty?
      beer_links = page.links.select { |link| link.uri.to_s[/beer\/\d+/] }
      link = beer_links[0]
      if link.nil?
        result.merge!({error: "No search results"})
      else
        if Nokogiri::HTML(link.click.body).css('.drank.tip').to_s.empty?
          result.merge!({check_in: "You have not had #{link.text} yet"})
        else
          result.merge!({check_in: "You have had  #{link.text} already"})
        end
      end
      true
    else
      false
    end
  end
end
