class PrerouteGroup < ActiveRecord::Base
  self.table_name = :racc_preroute_group
  self.primary_key = :preroute_group_id

  
  oath_keeper

  has_many :vlabel_maps
  has_many :preroute_grouping_xrefs, :dependent => :destroy
  has_many :preroute_groupings, :through => :preroute_grouping_xrefs

  attr_protected :app_id, :route_name
  validates_presence_of :app_id, :group_name, :preroute_enabled
  validates_length_of :group_name, :maximum => 64
  
  before_create :generate_route_name
  before_destroy :destroy_route
  
  scope :for, lambda {|app_id| where(app_id: app_id)}
  scope :enabled, where(preroute_enabled: 'T')
  scope :ordered, order(:group_name)
  scope :with_routes, (lambda do
    pg = PrerouteGroup.arel_table
    rr = RaccRoute.arel_table

    app_id_clause = pg[:app_id].eq(rr[:app_id])
    name_clause = pg[:route_name].eq(rr[:route_name])

    joined_pr = pg.join(rr, Arel::Nodes::OuterJoin).on(app_id_clause.and(name_clause)).join_sql
    joins(joined_pr)
  end)
  scope :with_rd_xref, (lambda do
    rr = RaccRoute.arel_table
    xref = RaccRouteDestinationXref.arel_table

    joined_rr = rr.join(xref, Arel::Nodes::OuterJoin).on(rr[:route_id].eq(xref[:route_id])).join_sql
    joins(joined_rr)
  end)

  [['Destination','destination_id'], ['VlabelMap', 'vlabel_map_id']].each do |klass, join_id|
    scope "with_#{klass.downcase}_exits", (lambda do
      join_obj = klass.classify.constantize.arel_table
      join_obj_alias = join_obj.alias(klass.first.downcase)
      rdx = RaccRouteDestinationXref.arel_table
  
      dest_id_clause = rdx[:destination_id].eq(join_obj_alias[join_id])
      exit_type_clause = rdx[:exit_type].eq(klass)
  
      joined_exits = rdx.join(join_obj_alias, Arel::Nodes::OuterJoin).on(dest_id_clause.and(exit_type_clause)).join_sql
      joins(joined_exits)
    end)
  end
  scope :with_mediafile_exits, (lambda do
    LabelDestinationMap.joins("LEFT OUTER JOIN #{MediaFile.raw_sql_prefix}recordings AS m ON racc_route_destination_xref.destination_id = m.recording_id AND racc_route_destination_xref.exit_type = 'MediaFile'") 
  end) 

  def generate_route_name
    millis = (Time.now.to_f * 1000).to_i
    self.route_name = "preroute[#{millis}]"
  end

  def racc_route
    RaccRoute.where(app_id: self.app_id, route_name: self.route_name).first
  end

  def racc_route_destination_xref
    racc_route.racc_route_destination_xrefs.first
  end
  
  def destroy_route
    DestroyRoute.destroy(route_name, app_id)
  end
  
  def self.with_exits(app_id)
    select_sql = "racc_preroute_group.preroute_group_id,
      racc_preroute_group.group_name,
      racc_preroute_group.preroute_enabled,
      (case racc_route_destination_xref.exit_type
        when 'Destination' then d.destination
        when 'VlabelMap' then v.vlabel
        when 'MediaFile' then m.keyword
        else ''
        end) as exit_value,
      (case racc_route_destination_xref.exit_type
        when 'Destination' then 'Destination'
        when 'VlabelMap' then 'Number/Label'
        when 'MediaFile' then 'Prompt'
        else ''
        end) as exit_type"
      
    PrerouteGroup.select(select_sql)
      .with_routes
      .with_rd_xref
      .with_destination_exits
      .with_vlabelmap_exits
      .with_mediafile_exits
      .where('racc_preroute_group.app_id = ?', app_id)
  end

  def in_use
    used = {}

    used["backend"] = VlabelMap.where("racc_vlabel_map.preroute_group_id = ? AND grp.category in (?,?)", self.id, 'b', 'x').
    joins("INNER JOIN web_groups grp ON grp.app_id = racc_vlabel_map.app_id AND REPLACE(racc_vlabel_map.vlabel_group, '_GEO_ROUTE_SUB','') = grp.name").
    select("racc_vlabel_map.*, grp.id AS group_id")

    used["frontend"] = Group.where("v.preroute_group_id = ? AND web_groups.category = ?", self.id, 'f').
    joins("INNER JOIN racc_vlabel_map v ON v.app_id = web_groups.app_id AND REPLACE(v.vlabel_group, '_GEO_ROUTE_SUB','') = web_groups.name").
    select("DISTINCT web_groups.id, web_groups.name")

    used["can_disable"] = used["backend"].empty? && used["frontend"].empty?
    used
  end

end
