# README

# Weather App

## Overview
The Weather App is a Ruby on Rails application that fetches weather data based on a ZIP code. It utilizes caching to store results and optimize API calls, ensuring faster responses for repeated requests.

## Features
- Fetches weather data using an external API.
- Caches responses to reduce redundant API calls.
- Implements RSpec tests for validation.

## Prerequisites
Ensure you have the following installed:
- Ruby 3.2.2
- Rails 7.x
- Bundler

## Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/weather-app.git
   cd weather-app
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the environment variables:
   Create a `.env` file in the root directory and add your API key:
   ```env
   WEATHER_API_KEY=your_api_key_here
   ```
   You may need to use `dotenv` gem to load environment variables.

4. Run the server:
   ```bash
   rails server
   ```
   Access the app at `http://localhost:3000`.

## Running Tests
To run RSpec tests, use:
```bash
rspec
```

## Deployment
To deploy the application, ensure your environment variables are correctly set in the production environment, and follow standard Rails deployment procedures.



