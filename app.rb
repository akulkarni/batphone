# app.rb
require 'sinatra'
require 'twilio-ruby'

class App < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  get '/' do
  	'Batmaaan!'
  end

  post '/call?' do
    client = get_twilio_client
    caller = params[:From]

    # only batphone participants if caller is not existing participant
    # allows batphone participant to join missed conference without calling everyone else
    unless get_conference_participants.include?(caller)
      get_conference_participants.each do |phone_number|
        client.messages.create(
          from: get_main_number,
          to: phone_number,
          body: 'Incoming call from: ' + caller
        )

        client.calls.create(
          from: get_main_number,
          to: phone_number,
          url: 'https://bat-phone-440.herokuapp.com/start_conference'
        )
      end
    end

    get_start_conference_xml

  end

  post '/start_conference?' do
  	get_start_conference_xml
  end

  post '/sms?' do
    sender = params[:From]
    message = params[:Body]
    client = get_twilio_client

    if get_conference_participants.include?(sender)
      client.messages.create(
        from: get_main_number,
        to: sender,
        body: "You can't reply to a message from this number."
      )
    else 
      get_conference_participants.each do |phone_number|
        client.messages.create(
          from: get_main_number,
          to: phone_number,
          body: 'from: ' + sender + "\n\n" + message
        )
      end
    end
  end


  ### internals

  def get_start_conference_xml
    Twilio::TwiML::Response.new do |r|
      r.Dial do |d|
      	d.Conference 'Batphone'
      end
      r.Say 'Goodbye'
    end.text    
  end

  def get_main_number
  	return '+14402021404'
  end

  def get_conference_participants
  	return ['+19175731568']
  end

  def get_twilio_client
    account_sid = "AC2c0c745ec4d44b2e8c34ce702d81dadd"
    auth_token = "4c8d9d87c5e4b1f0634a6a27e9bc9300"
    return Twilio::REST::Client.new account_sid, auth_token
  end

end 