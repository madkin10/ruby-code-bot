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
    share_url = "https://ruby-code-bot.herokuapp.com/share?token=#{params[:token]}&text=#{CGI.escape(params[:text])}"
    response = { attachments: [{ title: 'Code:', text: params['text'] }] }
    result = SafeRuby.eval(params['text'])
    response[:attachments] << { color: 'good', title: 'Result:', text: result.to_s }
    response[:attachments] << { type: 'button', text: 'Share', url: share_url }
    response.to_json
  rescue SyntaxError, StandardError => e
    response[:attachments] << { color: 'danger', title: 'Exception:', text: e.message }
    response[:attachments] << { type: 'button', text: 'Share', url: share_url }
    response.to_json
  end

  get '/share' do
    content_type :json
    response = { response_type: 'in_channel', attachments: [{ title: 'Code:', text: params['text'] }] }
    result = SafeRuby.eval(params['text'])
    response[:attachments] << { color: 'good', title: 'Result:', text: result.to_s }
    response.to_json
  rescue SyntaxError, StandardError => e
    response[:attachments] << { color: 'danger', title: 'Exception:', text: e.message }
    response.to_json
  end
end