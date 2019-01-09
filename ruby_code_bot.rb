require 'json'
require 'sinatra/base'
require 'safe_ruby'
require 'ostruct'


class RubyCodeBot < Sinatra::Base
  SLACK_TOKENS = ENV['SLACK_TOKENS']&.split || []
  SHARE_ACTION = 'share'.freeze

  before do
    if params[:token]
      token = params[:token]
    elsif params[:payload]
      payload = JSON.parse(params[:payload], object_class: OpenStruct)
      token = payload.token
    else
      token = nil
    end

    halt 401 unless SLACK_TOKENS.include?(token)
  end

  post '/execute' do
    content_type :json
    response = { response_type: 'in_channel', attachments: [{ title: 'Code:', text: "```#{params['text']}```", mrkdwn_in: ['text']}] }
    result = SafeRuby.eval(params['text'])
    response[:attachments] << { color: 'good', title: 'Result:', text: result.to_s }
    response.to_json
  rescue SyntaxError, StandardError => e
    response[:attachments] << { color: 'danger', title: 'Exception:', text: e.message }
    response.to_json
  end

  post '/message_action' do
    payload = JSON.parse(params[:payload], object_class: OpenStruct)
    puts payload.inspect

    case payload&.actions&.first&.name
    when 'share'
      puts 'share message'
    else
      puts 'Unhandled action'
    end
  end
end