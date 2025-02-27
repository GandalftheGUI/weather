class WeatherController < ApplicationController
  require 'net/http'
  require 'json'

  def search
    zip_code = params[:zip]

    if zip_code.blank?
      render json: { error: "ZIP code is required" }, status: :bad_request
      return
    end

    @weather = fetch_weather_by_zip(zip_code)
    render :index
  end

  private

  def fetch_weather_by_zip(zip_code)
    cache_key = "weather_#{zip_code}"
    cached_data = Rails.cache.read(cache_key)

    return cached_data.merge({ "source" => "cache" }) if cached_data

    weather_data = get_weather_from_api(zip_code)
    current_weather = get_current_weather(zip_code)

    if weather_data["cod"] == "200" && current_weather["cod"] == 200
      forecast = parse_forecast(weather_data)

      weather_info = {
        "location" => weather_data["city"]["name"],
        "current" => {
          "temperature" => current_weather["main"]["temp"],
          "temp_min" =>  current_weather["main"]["temp_min"],
          "temp_max" => current_weather["main"]["temp_max"],
          "conditions" => current_weather["weather"][0]["description"],
          "humidity" => current_weather["main"]["humidity"],
          "wind_speed" => current_weather["wind"]["speed"]
        },
        "forecast" => forecast
      }
      
      Rails.cache.write(cache_key, weather_info, expires_in: 30.minutes)
      weather_info.merge({ "source" => "API" })
    else
      { "error" => "Invalid ZIP code or data unavailable" }
    end
  end

  def get_weather_from_api(zip_code)
    url = URI("https://api.openweathermap.org/data/2.5/forecast?zip=#{zip_code},US&appid=#{ENV['OPENWEATHER_API_KEY']}&units=metric")
    response = Net::HTTP.get(url)
    JSON.parse(response)
  rescue StandardError => e
    Rails.logger.error "Weather API Error: #{e.message}"
    { "error" => "Failed to fetch forecast data" }
  end

  def get_current_weather(zip_code)
    url = URI("https://api.openweathermap.org/data/2.5/weather?zip=#{zip_code},US&appid=#{ENV['OPENWEATHER_API_KEY']}&units=metric")
    response = Net::HTTP.get(url)
    JSON.parse(response)
  rescue StandardError => e
    Rails.logger.error "Current Weather API Error: #{e.message}"
    { "error" => "Failed to fetch current weather data" }
  end

  def parse_forecast(weather_data)
    daily_temps = weather_data["list"].group_by { |entry| entry["dt_txt"].split(" ")[0] }

    forecast = daily_temps.map do |date, entries|
      temps = entries.map { |e| e["main"]["temp"] }
      { date: date, high: temps.max, low: temps.min }
    end

    forecast
  end
end
