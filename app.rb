# app.rb
require 'sinatra'
require 'twilio-ruby'

class App < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  @account_sid = "AC2c0c745ec4d44b2e8c34ce702d81dadd"
  @auth_token = "4c8d9d87c5e4b1f0634a6a27e9bc9300"

  get '/' do
  	'Bat man!'
  end

  post '/call?' do
    puts params
  end

  post '/sms?' do
    puts params
  end

end 