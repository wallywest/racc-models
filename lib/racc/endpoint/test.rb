require 'racc/app'

class Racc::App
  class Endpoint
    class Test < Endpoint
      set :prefix, '/test'

      get '/' do
        {"hello" => "world"}.to_json
      end

      get '/db' do
        binding.pry
        {"db" => "db"}.to_json
      end

    end
  end
end
