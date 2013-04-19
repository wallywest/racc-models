class Routing < ActiveRecord::Base
  self.table_name = "web_routings"
  belongs_to :time_segment, :inverse_of => :routings
  has_many :routing_exits, :inverse_of => :routing, :dependent => :destroy, :order => "call_priority ASC"
  #has_many :exits, :through => :routing_exits
  
  validates_presence_of :call_center, :app_id
  validates_numericality_of :percentage, :only_integer => true
  validates_inclusion_of :percentage, :in => 0..100, :message => "Should be between 0 and 100"
  
  before_validation :generate_call_center, :on => :create
  
  
  oath_keeper :master_event => {:type => Package, :finder => Proc.new {|t| t.time_segment.profile.package}}
  
  accepts_nested_attributes_for :routing_exits, :allow_destroy => true
  
  # After a routing is saved
  # First, delete all routing set errors
  # Second, check if the routings for the time segement equal 100%
  def validate_routes
    return unless time_segment
    self.time_segment.delete_routing_set_errors
    self.time_segment.check_routing_set_percent_is_100
  end

  # Generate a random string to populate the call center value (destid in racc platform)
  def generate_call_center
    self.call_center = rand(Time.now.to_i)
  end
  
  # Return an array of strings to from "1" to "100"
  def self.allocation_percentage_selects
    comma_delimited_list(Array("1".."100"))
  end
  
  # Return a comma separated list with values in single ticks
  # i.e. [dog, cat, bunny] => 'dog', 'cat', 'bunny'
  def self.comma_delimited_list(list)
    csv = ""
    list.each do |l|
        csv += "'#{l.to_s}', "
      end
      csv[0,csv.length-2]
  end
  
  # Return a comma delimited string of all destinations.
  # The destination list is returned from the Racc Platform racc_destination table
  def self.destination_selects(app_id)
    selects = Array.new
    Destination.select("destination, destination_title").where("app_id = ?", app_id).each do |dest|
      selects << dest.destination
    end
    comma_delimited_list(selects)
  end
  # END Select form choices
  
  # Used to create or update routing exit objects.
  # Routing exits include the exit and the call priority which allows
  # for backup numbers to call on the racc platform
  def routing_exit_attributes=(routing_exit_attributes) 
    routing_exit_attributes.each do |attributes| 
      if attributes[:id].blank?
        routing_exits.build(attributes) 
      else
        rd = routing_exits.detect { |r| r.id == attributes[:id].to_i }
        rd.attributes = attributes
      end
    end 
  end
  
  def copy
    r = self.dup
    r.attributes = {:created_at => nil, :updated_at => nil}
    r
  end
  
  def prioritize_exits
    cp = 1
    self.routing_exits.sort{|x,y| x.call_priority <=> y.call_priority }.each do |r|
      r.call_priority = cp
      r.save
      cp += 1
    end
  end
  
  def schedule_route
    RaccRoute.create!(:route_name => self.time_segment.profile.package.vlabel_map.vlabel, 
                      :day_of_week => self.time_segment.profile.create_day_of_week_base10_value,
                      :begin_time => self.time_segment.start_min,
                      :end_time => self.time_segment.end_min, 
                      :destid => self.call_center,
                      :distribution_percentage => self.percentage)
  end
  
  def schedule_exception_route
    RaccRouteException.create!(:route_exception_name => self.time_segment.profile.package.vlabel_map.vlabel, 
                      :route_exception_date => self.time_segment.profile.day_of_year,
                      :begin_time => self.time_segment.start_min,
                      :end_time => self.time_segment.end_min, 
                      :destid => self.call_center,
                      :distribution_percentage => self.percentage)
  end
  
  def package_id
    self.time_segment.profile.package.id
  end
  
  def profile_id
    self.time_segment.profile.id
  end
  
  def time_segment_id
    self.time_segment.id
  end
  
  def delete_routing_exit_set_errors
    RaccError.delete_all(["package_id = ? and profile_id = ? and time_segment_id = ? and routing_id = ?", self.package_id, self.profile_id, self.time_segment_id, self.id])
  end
  
  def check_routing_exits_are_valid
    exits = self.routing_exits.map(&:exit)
    exits.uniq.each do |e|
      # TODO: move this test into the Exit model
      if e.is_a?(Destination)
        self.generate_error("Destination #{e.destination} does not have a Dynamic IVR attached.") unless e.routable?
      end
    end
  end

  def generate_error msg
    RaccError.create({
      :error_message => msg,
      :package_id => self.package_id,
      :profile_id => self.profile_id,
      :time_segment_id => self.time_segment_id,
      :routing_id => self.id
    })
  end
end
