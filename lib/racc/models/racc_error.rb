class RaccError < ActiveRecord::Base
  self.table_name = "web_racc_errors"
  belongs_to :package
  
  scope :on_profiles, where('profile_id = -1 and time_segment_id = -1 and routing_id = -1')
  scope :on_time_segments, where('profile_id != -1 and time_segment_id = -1 and routing_id = -1')
  scope :on_routings, where('profile_id != -1 and time_segment_id != -1 and routing_id = -1')
  scope :on_routing_exits, where('profile_id != -1 and time_segment_id != -1 and routing_id != -1')
end
