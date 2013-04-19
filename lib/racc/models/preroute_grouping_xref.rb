class PrerouteGroupingXref < ActiveRecord::Base
  self.table_name = :web_preroute_groupings_xref
  
  oath_keeper :meta => [[:preroute_grouping,:name],[:preroute_group,:group_name]]
  
  belongs_to :preroute_grouping
  belongs_to :preroute_group
end
