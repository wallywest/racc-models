class RaccRouteDestinationXref < ActiveRecord::Base  
  self.table_name = "racc_route_destination_xref"
  self.primary_key = :route_destination_xref_id
  
  oath_keeper

  validates_presence_of :app_id, :route_id, :route_order, :modified_time, :modified_by
  validates_size_of :modified_by, :maximum => 64
  
  belongs_to :racc_route, :foreign_key => "route_id"
  belongs_to :exit, :foreign_key => 'destination_id', :polymorphic => true

  before_validation :set_app_id, :set_modified_fields

  scope :on_route, lambda {|name, app_id| joins(:racc_route).merge(RaccRoute.named(name).for(app_id))}

  scope :routed_to, lambda {|type| where(exit_type: type)}
  scope :for, lambda {|app_id| where(app_id: app_id)}

  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
  
  def set_modified_fields
    self.modified_time = Time.now
    self.modified_by ||= 'racc_admin'
  end
  
  # Todo Left the repetition in the two methods for now since drag and drop may be implemented and this will be obsolete
  def self.reorder(app_id, route_id)
    xrefs = RaccRouteDestinationXref.where("app_id = ? and route_id = ? ", app_id, route_id).order("route_id ASC")

    xrefs.each_with_index { |xref, i|
      xref.route_order = i + 1
      xref.save
    }
  end
  
  def self.dest_ids(app_id)
    RaccRouteDestinationXref.select("DISTINCT destination_id").where(:app_id => app_id).map(&:destination_id)
  end
	
	def self.all_dequeue_labels(app_id)
		where(:app_id => app_id).select("DISTINCT dequeue_label").map(&:dequeue_label)
	end
end
