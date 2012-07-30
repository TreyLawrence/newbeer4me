class BeersController < ApplicationController
  before_filter :signed_in_user, only: [:index, :search, :settings, :destroy]
  
  def index
  end
  
  def search
    if params[:search]
      if params[:type] == "beer"
        beer = Beer.new(params[:search].strip, params[:id], @browser)
        beer.spell_check?
        if beer.search_untappd
          render text: {result: render_to_string(beer), id: params[:id], type: params[:type]}.to_json
        else
          render text: {result: "Error logging in", id: params[:id], type: params[:type]}.to_json
        end
      else
        venue = Venue.new(params[:search].strip, params[:id], @browser)
        venue.search_beer_menus
        render text: {result: render_to_string(venue), id: params[:id], type: params[:type]}.to_json
      end
    else
      render text: {result: "No cookie", id: params[:id], type: params[:type]}.to_json
    end
  end
  
  def settings
    
  end
  
  def destroy
    @debug_string << "Deleting session\n"
    session[:password] = ""
    session[:name] = ""
    @session.destroy
    @session = nil
    @password = ""
    @user_signed_in = false
    redirect_to root_path
  end

  private
    
    def client_id
      "DLTI5SNFPYNXCV4AKZYYPZWXOFWLS3B2ZBGOWEC1DB1NO3BJ"
    end
end
