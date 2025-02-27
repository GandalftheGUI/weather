require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WeatherController, type: :controller do
  let(:valid_zip) { "94016" }
  let(:invalid_zip) { "00000" }
  let(:api_key) { "test_api_key" }
  let(:weather_response) do
    {
      "name" => "San Francisco",
      "sys" => { "country" => "US" },
      "main" => { "temp" => 15 },
      "weather" => [{ "description" => "clear sky" }],
      "cod" => 200
    }.to_json
  end

  before do
    # Mock the API response for a valid ZIP
    stub_request(:get, "https://api.openweathermap.org/data/2.5/weather?zip=#{valid_zip},US&appid=#{api_key}&units=metric")
      .to_return(status: 200, body: weather_response, headers: {})

    # Mock the API response for an invalid ZIP
    stub_request(:get, "https://api.openweathermap.org/data/2.5/weather?zip=#{invalid_zip},US&appid=#{api_key}&units=metric")
      .to_return(status: 404, body: { "cod" => 404, "message" => "city not found" }.to_json, headers: {})
  end

  describe "GET #index" do 
    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end

    it "returns a successful response" do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #search" do
    context "when given a valid ZIP code" do
      it "returns weather data and caches it" do
        Rails.cache.clear # Ensure clean cache before test

        get :search, params: { zip: valid_zip }

        expect(assigns(:weather)["name"]).to eq("San Francisco")
        expect(assigns(:weather)["source"]).to eq("API")

        # Check if it was cached
        cached_data = Rails.cache.read("weather_zip_#{valid_zip}")
        expect(cached_data).not_to be_nil
        expect(cached_data["name"]).to eq("San Francisco")
      end
    end

    context "when given an invalid ZIP code" do
      it "returns an error message" do
        get :search, params: { zip: invalid_zip }

        expect(assigns(:weather)["cod"]).to eq(404)
        expect(assigns(:weather)["message"]).to eq("city not found")
      end
    end

    context "when searching a second time for the same ZIP code" do
      it "fetches data from cache instead of API" do
        Rails.cache.write("weather_zip_#{valid_zip}", JSON.parse(weather_response).merge("source" => "cache"))

        get :search, params: { zip: valid_zip }

        expect(assigns(:weather)["source"]).to eq("cache")
      end
    end
  end
end
