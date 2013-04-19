class RaccRoute < ActiveRecord::Base
  self.table_name = "racc_route"
  self.primary_key = :route_id

  oath_keeper

  validates_presence_of :app_id, :route_name, :day_of_week, :begin_time, :end_time, :destid, :distribution_percentage
  validates_numericality_of :app_id, :day_of_week, :begin_time, :end_time, :distribution_percentage

  has_many :racc_route_destination_xrefs, :foreign_key => "route_id"
  has_many :destinations, :through => :racc_route_destination_xrefs

  before_validation :set_app_id, :set_modified_fields

  scope :named, lambda {|name| where(:route_name => name)}
  scope :for, lambda {|app_id| where(:app_id => app_id)}
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
  
  def set_modified_fields
    self.modified_time = Time.now
    self.modified_by ||= 'racc_admin'
  end
  
  #
  # NOTE: Since the racc_route and racc_vlabel_map tables are not linked by a conventional
  # foreign key (i.e. vlabel_map_id), I (Courtnie) had to link back to the racc_vlabel_map
  # table with this method.  Using the above belongs_to just returned nil.
  #
  def vlabel_map
    VlabelMap.find_by_app_id_and_vlabel(self.app_id, self.route_name)
  end
  
  def self.reload
    reload!
  end

  def destination=(_destination)
    #_destination.split(" : ").first
  end
  
  def add_new_racc_route_destination_xref(destination_id)
    xref = RaccRouteDestinationXref.create(:app_id => app_id, :route_id => route_id, 
                                        :destination_id => destination_id, :route_order => racc_route_destination_xrefs.length + 1,
                                        :modified_time => Time.now)
    racc_route_destination_xrefs << xref
  end

  def self.dow_to_char_bitmask(num)
    mask = num.to_s(2)

    while mask.length < 8
      mask = "0" << mask
    end
    mask
  end

  def self.new247route(name, exit)
    racc_route = RaccRoute.create!({
      :route_name => name,
      :day_of_week => 254,
      :begin_time => 0,
      :end_time => 1439,
      :distribution_percentage => 100, 
      :modified_time => Time.now,
      :app_id => exit.app_id,
      :destid => rand(9999999)
    })

    RaccRouteDestinationXref.create!({
      :route_id => racc_route.id,
      :exit => exit.source,
      :app_id => exit.app_id,
      :dtype => exit.dtype,
      :dequeue_label => exit.dequeue_value,
      :transfer_lookup => exit.transfer_lookup,
      :route_order => 1,
      :modified_time => Time.now
    })
    
    return racc_route
  end
end
