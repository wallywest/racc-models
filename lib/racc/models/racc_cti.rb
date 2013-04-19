class RaccCti < ActiveRecord::Base   
  self.table_name = "racc_cti"
  self.primary_key = :cti_id
  
  
  oath_keeper
  
  validates_uniqueness_of :cti_name, :scope => :app_id
  validates_presence_of :cti_name, :cti_order
  validates_length_of :cti_name, :maximum => 64
  validates_numericality_of :cti_order, :only_integer => true, :greater_than_or_equal_to => 0
  validates_length_of :vendor_type, :is => 1
  
  scope :for, lambda {|app_id| where(:app_id => app_id).order(:cti_name)}

  before_destroy :ensure_not_in_use

  HUMANIZED_ATTRIBUTES = {:cti_name => "CTI name", :cti_order => "CTI order"}

  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  def ensure_not_in_use
    errors.add(:base, "One or more CTI Hosts are using this CTI") if cti_hosts.any?
    errors.add(:base, "One or more Operations are using this CTI") if operations.any?
    errors.add(:base, "One or more Destination Properties are using this CTI") if destination_properties.any?
    errors.empty?
  end

  def cti_hosts
    RaccCtiHost.where(:app_id => app_id, :cti_name => cti_name)
  end

  def operations
    Operation.where(:app_id => app_id, :cti_name => cti_name)
  end

  def destination_properties
    DestinationProperty.where(:app_id => app_id, :queue_cti => cti_name)
  end
  
end
