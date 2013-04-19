class RoutingDestination < ActiveRecord::Base
  self.table_name = "web_routing_destinations"


  oath_keeper :master_event => {:type => Package, :finder => Proc.new {|t| t.routing.time_segment.profile.package}}

  belongs_to :routing, :inverse_of => :routing_destinations
  belongs_to :destination

  attr_writer :destination_string, :destination_property_name

  before_validation :set_app_id, :assign_destination, :set_destination_property

  validates_presence_of :app_id, :call_priority
  validates_presence_of :destination, :message => "can't be blank or invalid"
  validates_length_of :dequeue_label, :maximum => 64
  validate :verification_of_destination
  validate :existence_of_dequeue_label, :if => :destination_is_queue?
  
  scope :with_package, includes({:routing => {:time_segment => {:profile => :package}}})

  def destination_string
    if @destination_string
      @destination_string
    elsif destination
      destination.destination
    end
  end
  
  def destination_property_name
    if @destination_property_name
      @destination_property_name
    elsif destination
      destination.destination_property_name
    end
  end
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end

  def set_destination_property
    self.destination_property_name = self.destination.destination_property_name if self.destination
  end

  def copy
    rd = self.dup
    rd.attributes = {:created_at => nil, :updated_at => nil}
    rd
  end  
  
  private
  
  def assign_destination
    unless self.destination_string.blank?
      self.destination = Destination.find_by_destination_and_app_id(self.destination_string, self.app_id)
    end
  end
  
  def existence_of_dequeue_label
    vlabel = VlabelMap.find_by_vlabel_and_app_id(self.dequeue_label, self.app_id)
    errors.add(:dequeue_label, 'must exist') unless vlabel
  end
  
  def destination_is_queue?
    self.destination ? self.destination.is_queue? : false
  end
  
  def verification_of_destination
    if self.destination && !Destination.destination_verified_for_package(self.app_id, self.destination.destination)
      errors.add(:destination, "is not allowed to be used. #{Destination::DIVR_MESSAGE}")
    end
  end
end
