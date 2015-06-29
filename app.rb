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
    active_conferences = get_active_conferences(client)
    
    text_main_members(caller, client) unless get_main_members.include?(caller)

    if active_conferences.size == 0
      call_main_members(client, caller)
      sleep(10)
      get_start_conference_xml

    else
      conference_sid = active_conferences.first.sid
      num_outside_participants = get_number_outside_participants(conference_sid, client)

      if num_outside_participants == 0
        get_start_conference_xml
      else 
        text_missed_call_main_members(caller, client)
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
  def get_active_conferences(client)
    return client.account.conferences.list({
	  :status => "in-progress",
      :friendly_name => get_conference_id})
  end

  def get_number_outside_participants(conference_sid, client)
    num_outside_participants = 0
    conference = client.account.conferences.get(conference_sid)
    participants = conference.participants

    participants.list.each do |participant|
      participant_number = client.account.calls.get(participant.call_sid).from

      if !get_main_members.include?(participant_number)
        num_outside_participants = num_outside_participants + 1 
      end
    end

    return num_outside_participants
  end

  def text_main_members(caller, client)
    get_main_members.each do |phone_number|
      client.messages.create(
        from: get_main_number,
        to: phone_number,
        body: 'Incoming call from: ' + caller
      )
    end
  end

  def text_missed_call_main_members(caller, client)
    get_main_members.each do |phone_number|
      client.messages.create(
        from: get_main_number,
        to: phone_number,
        body: 'Missed call from: ' + caller
      )
    end
  end

  def call_main_members(client, caller)
  	get_main_members.each do |phone_number|
  	  unless phone_number == caller
        client.calls.create(
          from: get_main_number,
          to: phone_number,
          timeout: 4,
          url: get_host +  '/start_conference'
        )
      end
    end
  end

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
  	  r.Say "Sorry, we are currently unavailable. We'll call you right back."
    end.text
  end

end 