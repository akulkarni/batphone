# app.rb
require 'sinatra'
require 'twilio-ruby'

class App < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  get '/' do
  	'Bat man!'
  end

  post '/call?' do
    logger.info params

    from = params[:From]
    puts from

    client = get_twilio_client

    # client.messages.create(
    #   from: '+14402021404',
    #   to: '+19175731568',
    #   body: 'Incoming call from: ' + from
    # )

    call = client.calls.create(
     from: '+14402021404',
     to: '+19175731568',
     url: 'https://bat-phone-440.herokuapp.com/start_conference'
    )

    

    Twilio::TwiML::Response.new do |r|
      # r.Dial '+19175731568'
      r.Dial do |d|
        r.Conference 'Batphone'
      end
      r.Say 'Goodbye'
    end.text

  end

  get '/start_conference?' do
    Twilio::TwiML::Response.new do |r|
      r.Dial do |d|
        r.Conference 'Batphone'
      end
      r.Say 'Goodbye'
    end.text
  end

  post '/sms?' do
    logger.info params

    from = params[:From]
    body = params[:Body]

    client = get_twilio_client
    client.messages.create(
      from: '+14402021404',
      to: '+19175731568',
      body: 'from: ' + from + "\n\n" + body
    )
  end


  def get_twilio_client
    account_sid = "AC2c0c745ec4d44b2e8c34ce702d81dadd"
    auth_token = "4c8d9d87c5e4b1f0634a6a27e9bc9300"
    return Twilio::REST::Client.new account_sid, auth_token
  end
end 