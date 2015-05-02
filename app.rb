# app.rb
require 'sinatra'
require 'twilio-ruby'

require_relative 'init'
helpers BatConfig

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

    # Only send notification message if caller is not main member
    unless get_main_members.include?(caller)
      get_main_members.each do |phone_number|
        client.messages.create(
          from: get_main_number,
          to: phone_number,
          body: 'Incoming call from: ' + caller
        )

        client.calls.create(
          from: get_main_number,
          to: phone_number,
          url: get_host +  '/start_conference'
        )
      end
    end

    # Only let one caller who is not main member join
    num_outside_participants = 0
    client.account.conferences.get(get_conference_id).participants.list.each do |participant|
      num_outside_participants = num_outside_participants + 1 if !get_main_members.include?(participant)
    end

    if num_outside_participants < 2
      get_start_conference_xml
    else 
      get_try_again_xml
    end

  end

  post '/start_conference?' do
  	get_start_conference_xml
  end

  post '/sms?' do
    sender = params[:From]
    message = params[:Body]
    client = get_twilio_client

    if get_main_members.include?(sender)
      client.messages.create(
        from: get_main_number,
        to: sender,
        body: "You can't reply to a message from this number."
      )
    else 
      get_main_members.each do |phone_number|
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
      	r.Conference get_conference_id
      end
      r.Say 'Goodbye'
    end.text    
  end

  def get_try_again_xml
  	Twilio::TwiML::Response.new do |r|
  	  r.Say :voice => 'alice' do |s|
        "Sorry, we are currently on a call. We'll call you back."
      end
    end
  end

end 