require 'json'
require 'sinatra/base'
require 'safe_ruby'
require 'ostruct'
require 'rest-client'

class RubyCodeBot < Sinatra::Base
  SLACK_TOKENS = ENV['SLACK_TOKENS']&.split || []

  before do
    halt 401 unless SLACK_TOKENS.include?(token)
  end

  post '/execute' do
    content_type :json
    response = { response_type: 'in_channel', attachments: [{ title: 'Code:', text: "```#{params[:text]}```", mrkdwn_in: ['text']}] }
    result = SafeRuby.eval(params[:text])
    response[:attachments] << { color: 'good', title: 'Result:', text: result.to_s }
    RestClient.post(params[:response_url], response.to_json, headers: 'Content-Type: application/json')
    status :ok
  rescue SyntaxError, StandardError => e
    response[:attachments] << { color: 'danger', title: 'Exception:', text: e.message }
    RestClient.post(params[:response_url], response.to_json, headers: 'Content-Type: application/json')
    status :ok
  end
end