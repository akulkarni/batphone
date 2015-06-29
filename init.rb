# encoding: utf-8

module HotlineConfig

  def get_main_number
  	return '+14402021404'
  end

  def get_main_members
  	return [
  		'+19175731568', # Ajay mobile
  		# '+19173285297'  # Mike mobile
  	]
  end

  def get_conference_id
    return 'Hotline'
  end
  
  def get_host
  	return 'https://bat-phone-440.herokuapp.com'
  end

  def get_twilio_client
    account_sid = "AC2c0c745ec4d44b2e8c34ce702d81dadd"
    auth_token = "4c8d9d87c5e4b1f0634a6a27e9bc9300"
    return Twilio::REST::Client.new account_sid, auth_token
  end

end
