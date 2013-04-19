class PrerouteSelection < ActiveRecord::Base
  self.table_name = :web_preroute_selections
  
  
  oath_keeper :meta => [[:group,:display_name],
                        [:vlabel_map,:vlabel],
                        [:preroute_grouping,:name]]

  belongs_to :group
  belongs_to :vlabel_map
  has_one :preroute_grouping, :foreign_key => :id, :primary_key => :preroute_grouping_id
  
  def self.groups_and_vlabels(_app_id, preload_assoc=false)
    db_length = ActiveRecord::Base.connection.adapter_name.upcase =~ /MYSQL2/ ? "LENGTH" : "LEN"
    ps_sql = PrerouteSelection.
      select("ps.id, ps.app_id, ps.group_id, ps.vlabel_map_id, ps.preroute_grouping_id, vlm.vlabel, vlm.preroute_group_id, 
        (case when ps.group_id is null then vlm.position else g.position end) as group_position,
        (case when ps.group_id is null then vlm.display_name else g.display_name end) as group_display_name,
        (case when ps.group_id is null then vlm.category else g.category end) as group_category,
        (case when ps.group_id is null then vlm.name else g.name end) as group_name").
      from("web_preroute_selections ps").
      joins("LEFT OUTER JOIN web_groups g ON g.id = ps.group_id 
        LEFT OUTER JOIN (SELECT gg.name, gg.category, gg.id, gg.display_name, gg.position, vlm_g.vlabel, vlm_g.preroute_group_id, vlm_g.vlabel_map_id 
          FROM racc_vlabel_map vlm_g 
          INNER JOIN web_groups gg ON gg.app_id = vlm_g.app_id 
            AND gg.name = (CASE WHEN vlm_g.vlabel_group LIKE '%_GEO_ROUTE_SUB' THEN LEFT(vlm_g.vlabel_group, (#{db_length}(vlm_g.vlabel_group)-14)) ELSE vlm_g.vlabel_group END)) vlm 
        ON vlm.vlabel_map_id = ps.vlabel_map_id").
      where("ps.app_id = ?", _app_id)
    
    ps_sql = ps_sql.includes(:preroute_grouping => :preroute_groups) if preload_assoc
    
    ps_sql
  end
end
