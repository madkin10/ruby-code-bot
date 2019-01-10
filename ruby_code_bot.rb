require 'json'
require 'sinatra/base'
require 'safe_ruby'
require 'rest-client'

class RubyCodeBot < Sinatra::Base
  SLACK_TOKENS = ENV['SLACK_TOKENS']&.split || []

  before '/execute' do
    halt 401 unless SLACK_TOKENS.include?(params[:token])
  end

  get '/slack/oauth' do
    response = RestClient.get(
      'https://slack.com/api/oauth.access',
      params:
        {
          code: params[:code],
          client_id: ENV['CLIENT_ID'],
          client_secret: ENV['CLIENT_SECRET'],
          redirect_uri: ENV['HOST'] + '/slack/oauth'
        }
    )

    response.to_json
  end

  post '/execute' do
    content_type :json
    response = { response_type: 'in_channel', attachments: [{ title: "<@#{params[:user_id]}> Executed:", text: "```#{params[:text]}```", mrkdwn_in: ['text']}] }
    begin
      result = SafeRuby.eval(params[:text])
      response[:attachments] << { color: 'good', title: 'Result:', text: result.to_s }
    rescue SyntaxError, StandardError => e
      response[:attachments] << { color: 'danger', title: 'Exception:', text: e.message }
    end
    RestClient.post(params[:response_url], response.to_json, headers: 'Content-Type: application/json')
    status :ok
  end
end