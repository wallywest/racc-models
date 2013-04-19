class Location < Destination
  scope :with_default_xref, (lambda do
    loc = Location.arel_table
    xref = LabelDestinationMap.arel_table

    dest_id_clause = loc[:destination_id].eq(xref[:mapped_destination_id]) 
    vlabel_blank_clause = xref[:vlabel_map_id].eq(nil)

    locs_with_xrefs = loc.join(xref).on(dest_id_clause.and(vlabel_blank_clause)).join_sql

    joins(locs_with_xrefs)
  end)

  [['Destination','destination_id'], ['VlabelMap', 'vlabel_map_id']].each do |klass, join_id|
    scope "with_#{klass.downcase}_exits", (lambda do
      join_obj = klass.classify.constantize.arel_table
      join_obj_alias = join_obj.alias("#{klass.first.downcase}_exit")
      ldm = LabelDestinationMap.arel_table
  
      exit_id_clause = ldm[:exit_id].eq(join_obj_alias[join_id])
      exit_type_clause = ldm[:exit_type].eq(klass)
  
      joined_exits = ldm.join(join_obj_alias, Arel::Nodes::OuterJoin).on(exit_id_clause.and(exit_type_clause)).join_sql
      joins(joined_exits)
    end)
  end
  scope :with_mediafile_exits, (lambda do
    LabelDestinationMap.joins("LEFT OUTER JOIN #{MediaFile.raw_sql_prefix}recordings AS m_exit ON racc_label_destination_map.exit_id = m_exit.recording_id AND racc_label_destination_map.exit_type = 'MediaFile'") 
  end) 

  def self.for_mapped_dest_autocomplete(app_id, phrase, use_equals=false)
    dests = find_valid(app_id, phrase, use_equals)
    dests_not_mapped = dests.with_property.merge(DestinationProperty.not_mapped) if dests
    dests_not_mapped_no_queues = dests_not_mapped.merge(DestinationProperty.no_queues) if dests_not_mapped
    
    dests_not_mapped_no_queues || []
  end

  def self.with_default_exits(app_id)
    Location.
      mapped.
      with_default_xref.
      with_destination_exits.
      with_vlabelmap_exits.
      with_mediafile_exits.
      select("racc_destination.*, 
              racc_label_destination_map.*,
              (CASE
                WHEN racc_label_destination_map.exit_type = 'Destination' THEN d_exit.destination
                WHEN racc_label_destination_map.exit_type = 'VlabelMap' THEN v_exit.vlabel
                WHEN racc_label_destination_map.exit_type = 'MediaFile' THEN m_exit.keyword END) AS exit_label").
      where("racc_destination.app_id = ?", app_id)
  end

  def default_exit
    self.label_mappings.where("vlabel_map_id IS NULL").first
  end

end
