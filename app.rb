# app.rb
require 'sinatra'

class App < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  get '/' do
  	'Bat man!'
  end
end 