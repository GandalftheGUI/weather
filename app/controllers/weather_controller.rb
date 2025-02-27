require 'net/http'
require 'json'

class WeatherController < ApplicationController
  def index
  end

  def search
    zip = params[:zip]

    if zip.present?
      cache_key = "weather_zip_#{zip}"
      cached_data = Rails.cache.read(cache_key)

      if cached_data
        @weather = cached_data.merge("source" => "cache")
      else
        @weather = fetch_weather_by_zip(zip)
        Rails.cache.write(cache_key, @weather, expires_in: 30.minutes)
        @weather["source"] = "API"
      end
    else
      @weather = { error: "Please enter a ZIP code." }
    end

    render :index
  end

  private

  # Fetch weather using ZIP code
  def fetch_weather_by_zip(zip)
    api_key = ENV['OPENWEATHER_API_KEY']
    country = "US" # Default to US; modify if needed
    url = URI("https://api.openweathermap.org/data/2.5/weather?zip=#{zip},#{country}&appid=#{api_key}&units=metric")

    response = Net::HTTP.get(url)
    JSON.parse(response) rescue { error: "Invalid ZIP code or no data available." }
  end
end