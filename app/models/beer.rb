class Beer
  include ActiveModel::Validations
  attr_accessible :name, :spelling_correction, :check_in
  validates :name, presence: true
  
  def initialize beer_name
    @name = beer_name
    @spelling_correction = spell_check @name
    @
  end
  
  private
  
    def spell_check beer
      browser = Mechanize.new
      beer = beer.split.join('+')
      doc = Nokogiri::HTML(browser.get("http://www.google.com/search?q=#{beer}").body)
      spelling_correction = doc.css('a').select { |link| link['href'].include? "spell=1" }.first
      if !spelling_correction.nil?
        @debug_string << "Corrected to #{spelling_correction.text}\n"
        spelling_correction.text
      else
        @debug_string << "No spelling errors\n"
        ""
      end
    end
end
