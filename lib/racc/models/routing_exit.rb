class RoutingExit < ActiveRecord::Base
  self.table_name = "web_routing_destinations"

  oath_keeper :master_event => {:type => Package, :finder => Proc.new {|t| t.routing.time_segment.profile.package}}

  belongs_to :routing, :inverse_of => :routing_exits
  belongs_to :exit, :polymorphic => true

  validates_presence_of :app_id, :call_priority, :exit_id
  validate :route_to_self, :if => :route_exit?, :unless => :new_record?
  validate :verification_of_divr, :if => :destination_exit?

  scope :with_package, includes({:routing => {:time_segment => {:profile => :package}}})
  scope :routed_to, lambda {|type| where(exit_type: type)}
  scope :for, lambda {|app_id| where(app_id: app_id)}

  def copy
    rd = self.dup
    rd.attributes = {:created_at => nil, :updated_at => nil}
    rd
  end

  def verification_of_divr
    if self.exit && !Destination.destination_verified_for_package(self.app_id, self.exit.destination)
      errors.add(:destination, "is not allowed to be used. #{Destination::DIVR_MESSAGE}")
    end
  end

  def route_to_self
    vlabel_id = self.routing.time_segment.profile.package.vlabel_map.id
    if self.exit.id == vlabel_id
      errors.add(:package,"is not allowed to route to iself")
    end
  end

  def destination_exit?
    self.exit_type == "Destination"
  end

  def route_exit?
    self.exit_type == "VlabelMap"
  end

  def exit_object
    e = Exit.new(self, self.app_id)
  end

  def exit_value
    exit_object.value
  end

  def exit_description
    exit_object.description
  end

  def exit_has_dequeue?
    !exit_dequeue.blank?
  end

  def exit_dequeue
    exit_object.dequeue_value
  end

  def exit_has_dequeue=(value)
  end

  def exit_value=(value)
  end

  def exit_dequeue=(value)
  end
end
