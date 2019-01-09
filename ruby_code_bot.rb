require 'json'
require 'sinatra/base'
require 'safe_ruby'


class RubyCodeBot < Sinatra::Base
  SLACK_TOKENS = ENV['SLACK_TOKENS']&.split || []

  before do
    halt 401 unless SLACK_TOKENS.include?(params[:token])
  end

  post '/execute' do
    content_type :json
    result = SafeRuby.eval(params['text'])
    response = { attachments: [{ title: 'Code:', text: params['text'] }] }
    response[:attachments] << { color: 'good', title: 'Result:', text: result.to_s }
  rescue SyntaxError, StandardError => e
    response[:attachments] << { color: 'danger', title: 'Exception:', text: e.message }
  ensure
    response.to_json
  end
end
