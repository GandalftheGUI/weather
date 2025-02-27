require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WeatherController, type: :controller do
  let(:valid_zip) { "10001" } # New York ZIP code
  let(:invalid_zip) { "00000" }
  let(:cache_key) { "weather_#{valid_zip}" }

  let(:forecast_data) do
    {
      "cod" => "200",
      "city" => { "name" => "New York" },
      "list" => [
        { "dt_txt" => "2025-02-27 12:00:00", "main" => { "temp" => 10 } },
        { "dt_txt" => "2025-02-27 18:00:00", "main" => { "temp" => 12 } },
        { "dt_txt" => "2025-02-28 12:00:00", "main" => { "temp" => 8 } },
        { "dt_txt" => "2025-02-28 18:00:00", "main" => { "temp" => 9 } }
      ]
    }
  end

  let(:current_weather_data) do
    {
      "cod" => 200,
      "main" => { "temp" => 15, "humidity" => 60, "temp_min" => 10, "temp_max" => 20 },
      "weather" => [{ "description" => "Clear sky" }],
      "wind" => { "speed" => 5 }
    }
  end

  let(:expected_weather_response) do
    {
      "location" => "New York",
      "current" => {
        "temperature" => 15,
        "temp_max" => 20,
        "temp_min" => 10,
        "conditions" => "Clear sky",
        "humidity" => 60,
        "wind_speed" => 5
      },
      "forecast" => [
        { date: "2025-02-27", high: 12, low: 10 },
        { date: "2025-02-28", high: 9, low: 8 }
      ],
      "source" => "API"
    }
  end

  before do
    allow(Rails.cache).to receive(:read).and_return(nil) # Clear cache before each test
    allow(Rails.cache).to receive(:write) # Stub cache writes

    stub_request(:get, /api.openweathermap.org\/data\/2.5\/forecast/)
      .to_return(status: 200, body: forecast_data.to_json, headers: {})

    stub_request(:get, /api.openweathermap.org\/data\/2.5\/weather/)
      .to_return(status: 200, body: current_weather_data.to_json, headers: {})
  end

  describe "GET #index" do
    before { get :index }

    it "renders the index template" do
      expect(response).to render_template(:index)
    end

    it "assigns @weather" do
      expect(assigns(:weather)).to be_nil
    end

    it "gets 200 status" do
      expect(response).to have_http_status(:ok)
    end
  end


  describe "GET #search" do
    context "when given a valid ZIP code" do
      before { get :search, params: { zip: valid_zip } }

      it "returns weather data including current weather and forecast" do
        expect(assigns(:weather)).to eq(expected_weather_response)
      end

      it "caches the weather data" do
        expect(Rails.cache).to have_received(:write).with(
          cache_key,
          hash_including("location" => "New York"),
          expires_in: 30.minutes
        )
      end
    end

    context "when searching a second time for the same ZIP code" do
      it "fetches data from cache instead of API" do
        allow(Rails.cache).to receive(:read).with(cache_key).and_return(expected_weather_response)

        get :search, params: { zip: valid_zip }

        expect(assigns(:weather)).to eq(expected_weather_response.merge("source" => "Cache"))
      end
    end

    context "when given an invalid ZIP code" do
      before do
        stub_request(:get, /api.openweathermap.org\/data\/2.5\/forecast/)
          .to_return(status: 404, body: { "cod" => "404" }.to_json)

        stub_request(:get, /api.openweathermap.org\/data\/2.5\/weather/)
          .to_return(status: 404, body: { "cod" => 404 }.to_json)

        get :search, params: { zip: invalid_zip }
      end

      it "returns an error message" do
        expect(assigns(:weather)).to eq({ "error" => "Invalid ZIP code or data unavailable" })
      end
    end

    context "when no ZIP code is provided" do
      before { get :search, params: { zip: "" } }

      it "returns a bad request error" do
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({ "error" => "ZIP code is required" })
      end
    end
  end
end
