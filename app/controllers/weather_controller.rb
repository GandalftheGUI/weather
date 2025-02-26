# frozen_string_literal: true

require 'net/http'
require 'json'

#  WeatherController
class WeatherController < ApplicationController
  def index; end

  def search
    city = params[:city]
    if city.present?
      @weather = fetch_weather(city)
    else
      @weather = { error: "Please enter a city name" }
    end
    render :index
  end

  private

  def fetch_weather(city)
    api_key = ENV['OPENWEATHER_API_KEY']
    url = "https://api.openweathermap.org/data/2.5/weather?q=#{URI.encode_www_form_component(city)}&appid=#{api_key}&units=metric"

    response = Net::HTTP.get(URI(url))
    JSON.parse(response) rescue { error: "Invalid response from weather service" }
  end
end
