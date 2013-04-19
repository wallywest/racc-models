class RaccRouteExceptionDestinationXref < ActiveRecord::Base
  self.table_name = "racc_route_exception_destination_xref"
  self.primary_key = :route_exception_destination_xref_id
  
  #belongs_to :racc_route_exception, :foreign_key => "route_exception_id"
  #belongs_to :destination, :foreign_key => "app_id,destination"
end
