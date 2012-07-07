class Beer
  include ActiveModel::Validations
  attr_accessor :name, :spelling_correction, :check_in, :errors
  validates :name, presence: true
  
  def initialize beer_name, mechanize_object
    @errors = ""
    @browser = mechanize_object
    @name = beer_name
  end
  
  def spell_check?
    doc = Nokogiri::HTML(@browser.get("http://www.google.com/search?q=#{@name}").body)
    correction_link = doc.css('a').select { |link| link['href'].include? "spell=1" }.first
    if !correction_link.nil?
      @spelling_correction = spelling_correction.text
      true
    else
      @spelling_correction = @name
      false
    end
  end
  
  def search_untappd
    page = @browser.get("http://untappd.com/search?q=#{@spelling_correction}")
    
    if page.uri.path.include? "login"
      @errors << "User not signed in\n"
      false
    else
      beer_links = page.links.select { |link| link.uri.to_s[/beer\/\d+/] }
      link = beer_links[0]
      if link.nil?
        @errors << "Untappd search has no results\n"
        false
      else
        if Nokogiri::HTML(link.click.body).css('.drank.tip').to_s.empty?
          @check_in = "You have checked into #{link.to_s} before.\n"
        else
          @check_in = "You have not checked into #{link.to_s} before.\n"
        end
        true
      end
    end
  end
end
