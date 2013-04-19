class DestinationAttributeBit < ActiveRecord::Base
  self.table_name = :web_destination_attribute_bits
  
  validates_presence_of :description, :if => Proc.new{ |bit| bit.display }
  
  scope :displayed, where(["display = ?", true]).order("decimal_value DESC")
end
