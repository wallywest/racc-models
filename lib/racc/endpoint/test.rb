require 'racc/app'

class Racc::App
  class Endpoint
    class Test < Endpoint
      set :prefix, '/test'

      get '/' do
        {"hello" => "world"}
      end

    end
  end
end
