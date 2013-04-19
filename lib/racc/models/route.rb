class Route
  #will implement later
  ROUTE_TYPES = [
    :divr,
    :vlabel,
    :mapped_vlabels,
    :locations,
    :frontend_groups,
    :preroute_groups,
    :georoute_groups,
    :survey_groups,
    :default_groups
  ]

  attr_reader :destination

  def initialize(destination)
    @destination = destination
    @routed = false
    @used_types = []
    used_routes = @destination.find_used_routes

    (class << self; self; end).class_eval do
      used_routes.each_pair do |key,value|
        next if key == :routed
        define_method key do
          value
        end

        define_method "has_#{key}?" do
          field = self.send(key).compact
          field ||= []
          !field.empty?
        end
      end
    end
    @used_routes = used_routes
  end

  def routed?
    @used_routes[:routed] ||= @routed
  end
end
