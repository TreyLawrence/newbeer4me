class BeersController < ApplicationController
  before_filter :signed_in_user, only: [:index, :search, :settings, :destroy]
  
  def index
  end

  def search
    if params[:search]
      if params[:type] == "beer"
        beer = Beer.new(params[:search].strip, "beer"+params[:id].to_s, browser)
        beer.spell_check
        if beer.search_untappd
          render text: {result: render_to_string(beer), id: params[:id], type: params[:type]}.to_json
        else
          render text: {result: "Error logging in", id: params[:id], type: params[:type]}.to_json
        end
      elsif params[:type] == "venue"
        venue = Venue.new(params[:search].strip, "venue"+params[:id], browser)
        venue.spell_check
        venue.search_untappd
        render text: {result: render_to_string(venue), id: params[:id], type: params[:type]}.to_json
      end
    else
      render text: {result: "No cookie", id: params[:id], type: params[:type]}.to_json
    end
  end

  def checkin
    shout = JSON.parse(params[:checkin])['shout'] rescue nil

    if shout =~ /beer/i
      foursquare_id = JSON.parse(params[:checkin])['user']['id']
      current_user = User.find_by_foursquare_id(foursquare_id)
      venue_name = JSON.parse(params[:checkin])['venue']['name']
      checkin_id = JSON.parse(params[:checkin])['id']

      if current_user
        current_user.process_foursquare_checkin(venue_name, checkin_id)
      end
    end
    
    render nothing: true
  end
end
