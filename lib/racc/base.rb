require 'racc/app'
require 'sinatra/base'

class Racc::App
  class Base < Sinatra::Base
    def call(env)
     super
     rescue Sinatra::NotFound
    end

    configure do
      disable :setup
      enable :raise_errors
      register Racc::App::Extensions::SubclassTracker
    end

    configure :development do
      set :show_exceptions, :after_handler
    end

  end
end
