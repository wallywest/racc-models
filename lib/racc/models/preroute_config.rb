class PrerouteConfig

  attr_reader :app_id, :many_to_one_groups, :one_to_one_groups, :selected_vlabels, :selected_groups, :selected_groups_for_vlabels,
    :selected_one_to_one_groups, :selected_many_to_one_groups, :selected_vlabels_ids, :selected_groups_ids,:preroute_ids_for_groups

  def self.for(app_id)
    new(app_id)
  end

  def initialize(app_id)
    @app_id = app_id
    setup_vars
  end

  def setup_vars
    #returns groups
    @preroute_groups = Group.groups_with_preroutes(@app_id).select {|g| g.vlabel_maps.size > 0}

    #returns preroutes_selections
    @current_preroutes = PrerouteSelection.groups_and_vlabels(@app_id,true)
  end

  def update(group_ids,vlabel_ids)
    begin
      destroy_unused(group_ids,vlabel_ids)
      create_or_update(group_ids,vlabel_ids)
      return true
    rescue ActiveRecord::RecordInvalid => e
      return false
    end
  end

  def destroy_unused(gids,vids)
    gdelete = deleted_keys(selected_groups_ids,gids)
    vdelete = deleted_keys(selected_vlabels_ids,vids)
    PrerouteSelection.destroy_all(["vlabel_map_id IN (?) AND app_id = ?",vdelete,@app_id]) unless vdelete.empty?
    PrerouteSelection.destroy_all(["group_id IN (?) AND app_id = ?",gdelete,@app_id]) unless gdelete.empty?
  end

  def deleted_keys(current, new)
    return current if new.empty?
    return current - (new.keys.map {|x| x.to_i})
  end

  def create_or_update(gids,vids)
    gids.each do |gid,grouping|
      pg = PrerouteSelection.where(:app_id => @app_id,:vlabel_map_id => nil, :group_id => gid).first_or_create(:preroute_grouping_id => grouping)
      if pg.preroute_grouping_id.nil? || pg.preroute_grouping_id != grouping.to_i
        pg.preroute_grouping_id = grouping
        pg.save
      end
    end unless gids.empty?

    vids.each do |vid,grouping|
      pg = PrerouteSelection.where(:app_id => @app_id,:vlabel_map_id => vid, :group_id => nil).first_or_create(:preroute_grouping_id => grouping)
      if pg.preroute_grouping_id.nil? || pg.preroute_grouping_id != grouping.to_i
        pg.preroute_grouping_id = grouping
        pg.save
      end
    end unless vids.empty?
  end

  #selectors
  def many_to_one_groups
    @preroute_groups.select {|s| s.category == "f"}
  end

  def one_to_one_groups
    @preroute_groups.select {|s| ['b','x'].include?(s.category) }
  end

  def selected_vlabels
    #@current_preroutes.map{ |ps| ps.vlabel_map_id unless ps.vlabel_map_id.nil? }.compact
    @current_preroutes.select { |ps| ps unless ps.vlabel_map_id.nil? }.compact
  end

  def selected_vlabels_ids
    selected_vlabels.map {|ps| ps.vlabel_map_id}
  end

  def selected_groups_ids
    selected_groups.map {|ps| ps.group_id}
  end

  def selected_groups
    @current_preroutes.select{ |ps| ps unless ps.group_id.nil? }.compact
  end
  
  def selected_groups_for_vlabels
    @current_preroutes.map { |ps| ps.group_name if !ps.vlabel_map_id.nil? }.compact.uniq
  end

  def selected_many_to_one_groups
    @current_preroutes.select{ |ps| ps.group_category == "f"}.sort{|x,y| x.group_position <=> y.group_position}
  end
  
  def selected_one_to_one_groups
    @current_preroutes.select{ |ps| ["b","x"].include?(ps.group_category)}.sort{|x,y| x.group_position <=> y.group_position}
  end

  def preroute_ids_for_groups
    ids = {}
    @preroute_groups.each do |g|
      ids[g.id] = g.vlabel_maps.first.preroute_group_id
    end
    ids
  end
end
