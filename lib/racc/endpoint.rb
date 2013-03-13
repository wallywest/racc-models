require 'racc/app'

class Racc::App
  class Endpoint < Base
    set(:prefix) { "/" << name[/[^:]+$/].underscore }
    before { content_type :json }
  end
end
