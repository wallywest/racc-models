require 'racc/app'

class Racc::App
  module Extensions
    require_relative 'extensions/subclass_tracker'
  end
end
