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
    puts params
    result = execute params['text']
    { text: 'Result:', attachments: [text: result.to_s] }.to_json
  end

  def execute(code)
    code.untaint
    proc do
      $SAFE = 1
      BlankSlate.new.instance_eval do
        binding
      end.eval(code)
    end.call
  end

  class BlankSlate
    instance_methods.each do |name|
      class_eval do
        unless name =~ /^__|^instance_eval$|^binding$|^object_id$/
          undef_method name
        end
      end
    end
  end
end
