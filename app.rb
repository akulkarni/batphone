# app.rb
require 'sinatra'
require 'twilio-ruby'

require_relative 'init'

class App < Sinatra::Base
  helpers HotlineConfig

  configure :production, :development do
    enable :logging
  end

  get '/' do
  	return 200
  end

  post '/call?' do
    client = get_twilio_client
    caller = params[:From]

    active_calls = client.account.conferences.list({
	  :status => "in-progress",
      :friendly_name => get_conference_id})
    
    if active_calls.size == 0
      if !get_main_members.include?(caller)
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
      get_start_conference_xml

    else
      conference_sid = active_calls.first.sid
      num_outside_participants = 0

      client.account.conferences.get(conference_sid).participants.list.each do |participant|
      	puts participant
      	participant_number = client.account.calls.get(participant.call_sid).from

      	if !get_main_members.include?(participant_number)
          num_outside_participants = num_outside_participants + 1 
        end
      end

      if num_outside_participants < 2
        get_start_conference_xml
      else 
        get_main_members.each do |phone_number|
		  client.messages.create(
            from: get_main_number,
            to: phone_number,
            body: 'Missed call from: ' + caller
          )
        end
        get_try_again_xml
      end

    end
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

  post '/start_conference?' do
  	get_start_conference_xml
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
  	  r.Say "Sorry, we are currently on a call. We'll call you right back."
    end.text
  end

end 