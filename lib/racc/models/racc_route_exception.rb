class RaccRouteException < ActiveRecord::Base
  self.table_name = "racc_route_exception"
  self.primary_key = :route_exception_id
  
  has_many :racc_route_exception_destination_xrefs, :foreign_key => "route_exception_id"
  
  before_validation :set_app_id, :set_modified_fields
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
  
  def set_modified_fields
    self.modified_time = Time.now
    self.modified_by ||= 'racc_admin'
  end
end
