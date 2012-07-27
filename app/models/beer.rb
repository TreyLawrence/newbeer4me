class Beer
  include ActiveModel::Validations
  attr_accessor :name, :result, :id
  validates :name, presence: true
  
  def initialize beer_name, beer_id, mechanize_object
    @errors = ""
    @browser = mechanize_object
    @name = beer_name
    @id = beer_id
    @result = {name: "Searched for #{@name}"}
  end
  
  def spell_check?
    doc = Nokogiri::HTML(@browser.get("http://www.google.com/search?q=#{@name + ' beer'}").body)
    correction_link = doc.css('a').select { |link| link['href'].include? "spell=1" }.first
    if correction_link.nil?
      false
    else
      result.merge!({spell_check: "Spell checked to: " + correction_link.text.split[0..-2].join(' ')})
      true
    end
  end
  
  def search_untappd
    if result[:spell_check]
      query = result[:spell_check].gsub("Spell checked to: ", "")
    else
      query = @name
    end
    page = @browser.get("http://untappd.com/search?q=#{query}")
    
    if page.links.select { |link| link.uri.to_s[/login/] rescue nil}.empty?
      beer_links = page.links.select { |link| link.uri.to_s[/beer\/\d+/] rescue nil }
      link = beer_links[0]
      if link.nil?
        result.merge!({untappd: "No search results"})
      else
        doc = Nokogiri::HTML(link.click.body)
        brewery_and_beer_name = doc.css('a').select {|link| link['href'].include? "brewery" }.first.text + ' ' + link.text
        if doc.css('.drank.tip').to_s.empty?
          result.merge!({untappd: "You have not had #{brewery_and_beer_name} yet"})
        else
          result.merge!({untappd: "You have had  #{brewery_and_beer_name} already"})
        end
      end
      true
    else
      result.merge!({untappd: "Error logging into Untappd"})
      false
    end
  end
end