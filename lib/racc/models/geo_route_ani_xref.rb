class GeoRouteAniXref < ActiveRecord::Base
  self.table_name = 'racc_geo_route_ani_xref'
  self.primary_key = :geo_route_ani_xref_id

  
  oath_keeper :meta => [[:geo_route_group,:name],[:ani_group,:name]]

  validates_presence_of :app_id, :ani_group_id
  validates_presence_of :route_name, :message => "must be selected"
  
  belongs_to :geo_route_group
  belongs_to :ani_group
  belongs_to :racc_route, :foreign_key => :route_name, :primary_key => :route_name
  
  before_validation :set_app_id
  
  attr_accessible :geo_route_ani_xref_id, :ani_group_id, :route_name, :app_id, :geo_route_group_id
  
  private
    def set_app_id
      self.app_id ||= ThreadLocalHelper.thread_local_app_id
    end

    def current_time_in_millis
      (Time.now.to_f * 1000).to_i
    end
end
