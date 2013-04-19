class RaccDst < ActiveRecord::Base     
  self.table_name = "racc_dst"
  self.primary_key = "dst_name"
  
  
  oath_keeper
  
  validates_presence_of :dst_name, :start_type, :local_start_month, :local_start_minute, :end_type, :local_end_month, :local_end_minute, :gmt_offset, :dst_adjust
  
  def self.selects
    self.order('dst_name').collect { |dst| dst.dst_name }
  end
end
