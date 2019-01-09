require 'json'
require 'rest-client'
require 'sinatra/base'


class RubyCodeBot < Sinatra::Base
  SLACK_TOKENS = ENV['SLACK_TOKENS']&.split || []

  before do
    halt 401 unless SLACK_TOKENS.include?(params[:token])
  end

  post '/execute' do
    content_type :json
    result = SafeRuby.eval(params['text'])
    { text: 'Result:', attachments: [text: result.to_s] }.to_json
  rescue SyntaxError, StandardError => e
    { text: 'Exception:', attachments: [text: e.message] }.to_json
  end
end
