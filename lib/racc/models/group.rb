class Group < ActiveRecord::Base
  self.table_name = "web_groups"
  
  
  oath_keeper
  
  has_many :vlabel_maps, :finder_sql => proc { 
    "select * from racc_vlabel_map where app_id='#{app_id}' and (vlabel_group='#{name}' OR vlabel_group = '#{name}_GEO_ROUTE_SUB')"
  }
  has_many :group_cti_routine_xrefs, :dependent => :destroy
  has_many :cti_routines, :through => :group_cti_routine_xrefs
  has_many :group_default_routes, :dependent => :destroy
  has_many :default_routes, :through => :group_default_routes, :source => :vlabel_map
  has_one :preroute_selection
  
  belongs_to :company, :foreign_key => "app_id"
  belongs_to :operation, :dependent => :destroy
  
  validates_presence_of :name, :operation_id
  validates :display_name, :presence => {:message => "can't be blank if the group is displayed."}, :length => {:maximum => 20}, :if => Proc.new{ |grp| !grp.group_default && grp.show_display_name }
  validates_uniqueness_of :name, :scope => :app_id
  validates_format_of :name, :with => /\A[[:upper:][:lower:]\d_]+\Z/, :message => "may only have letters, numbers, and underscores."
  validates_presence_of :cti_routine_ids, :unless => :in_default
  validates_presence_of :override_route, :if => :override_is_on
  validates_presence_of :default_route_ids, :if => :limit_is_set

  accepts_nested_attributes_for :operation

  attr_accessor :default_cti_routine_id, :override_mode, :override_route

  HUMANIZED_ATTRIBUTES = {:cti_routine_ids => "Available CTI Routines", :default_route_ids => "Available Default Routes"}
  GEO_ROUTE_DEFAULT_GROUP_NAME = "Geo_Route_Default_Group"
  DEFAULT_OVERRIDE_DISPLAY_NAME = 'Override Routes'
  DEFAULT_F_DISPLAY_NAME = 'Default Routes'
  DEFAULT_GEO_ROUTE_DISPLAY_NAME = 'Geo-Route Packages'
  DEFAULT_ROUTE_FILTER_ALL = 'A'
  DEFAULT_ROUTE_FILTER_LIMIT = 'L'
  DEFAULT_ROUTE_FILTER_LIMIT_AND_NEW = 'N'

  scope :visible, lambda { |app_id| where(["app_id = ? AND group_default = ? AND show_display_name = ?", app_id, false, true]) } 
  scope :many_to_one, lambda { |app_id| where("category = ? and app_id = ? and group_default = ?", 'f', app_id, false).order("name ASC") }
  
  
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def in_default
    self.group_default
  end

  def override_is_on
    self.override_mode == "on"
  end
  
  def recent_vlabel_maps(limit)
    VlabelMap.in_group(self.app_id, self.name).limit(limit).order('modified_time DESC')
  end
  
  def vlabel_maps_with_packages(limit=nil)
    vlm_pkgs = VlabelMap.in_group(self.app_id, self.name).order('modified_time DESC').includes(:packages)
    vlm_pkgs = vlm_pkgs.limit(limit) if limit
    vlm_pkgs
  end
  
  def paginated_vlabel_maps(_page_number, _options={})
    vlm_query = VlabelMap.in_group(self.app_id, self.name).order(:vlabel)
    vlm_query = vlm_query.includes(_options[:include]) if _options[:include]
    vlm_query.paginate(:page => _page_number, :per_page => _options[:per_page]).to_a
  end
  
  def vlabel_maps_ordered(order_field, include_grouping=false)
    vlm_query = VlabelMap.in_group(self.app_id, self.name).order(order_field)
    vlm_query = vlm_query.includes(:preroute_selection => :preroute_grouping) if include_grouping
    vlm_query
  end
    
  def self.frontend_number_groups_on_display(app_id)
    @groups = where("category = ? and app_id = ? and group_default = ? and show_display_name = ?", 'f', app_id, false, true).order(:position)
  end
  
  def self.backend_number_groups_on_display(app_id)
    @groups = where("category in ('b','x') and app_id = ? and group_default = ? and show_display_name = ?", app_id, false, true).order(:position)
  end
  
  def self.default_groups_on_display(app_id)
    @groups = where("app_id = ? and group_default = ? and show_display_name = ?", app_id, true, true).order(:position)
  end
  
  def name_for_display
    self.display_name.blank? ? self.name : self.display_name
  end
  
  def name_for_display_on_index
    self.display_name.blank? ? "No display name for #{self.name}" : self.display_name
  end
  
  def self.find_backend_number_group app_id
    Group.find_by_category('b', :conditions => ["app_id = ? AND group_default = ?", app_id, false])
  end

  def self.find_translation_route_group app_id
    Group.find_by_category('x', :conditions => ["app_id = ? AND group_default = ?", app_id, false])
  end
  
  def audit_preroute_group(preroute_group_id, user_login, app_id)
    #CHANGE THIS FOR NEW AUDITS
    new_preroute_group_name = preroute_group_id.blank? ? 'None in use' : PrerouteGroup.find(preroute_group_id).group_name
    Audit.create( {:auditable_id => self.id, 
                    :auditable_type => self.class.to_s, 
                    :username => user_login, 
                    :action => 'update', 
                    :audited_changes => {:preroute_group => new_preroute_group_name}, 
                    :app_id => app_id, 
                    :created_at => Time.now} )  
  end
  
  def preroute_group_changed?(new_preroute_group_id)
    self.vlabel_maps.size > 0 and self.vlabel_maps[0].preroute_group_changed?(new_preroute_group_id)
  end
  
  def copy_group_and_operation(new_group_attributes)
    new_group = nil
    new_group_name = new_group_attributes[:name]

    begin
      ActiveRecord::Base.transaction do
        new_operation = self.operation.dup
        new_operation.attributes = {:vlabel_group => new_group_name}
        new_operation.save
    
        new_group = self.dup
        new_group_attributes[:operation_id] = new_operation.id
        zero_cti_routine = CtiRoutine.first(:conditions => {:app_id => new_group.app_id, :value => 0}) || CtiRoutine.create(:app_id => new_group.app_id, :value => 0, :description => "No CTI Interaction", :modified_by => new_operation.modified_by)        
        new_group.attributes = new_group_attributes.merge(:cti_routine_ids => [zero_cti_routine.id])
        new_group.created_at = Time.now
        new_group.updated_at = Time.now
        new_group.save

        new_group.group_cti_routine_xrefs[0].update_attributes(:default_cti_for_group => true, :modified_by => new_operation.modified_by)
      end
    rescue => e
      logger.error e.to_s
    end
    
    new_group
  end

  def category_for_display
    if self.group_default
      "Default"
    else
      case self.category
      when 'f'
        "Front End"
      when 'b', 'x'
        "Back End"
      else
        "Unknown Group Type"
      end
    end
  end
  
  def individual_mode?
    op = self.operation
    op.operation == 11 ? false : true
  end
  
  def can_override?(_operation)
    ['b','x'].include?(self.category) && [11, 6, 9].include?(_operation)
  end
  
  def disable_operation_field?
    self.category != 'f' && !self.individual_mode?
  end
  
  def default_cti_routine_id
    @default_cti_routine_id ||= (default_cti_routine_record ? default_cti_routine_record.id : nil)
  end
  
  def default_cti_routine_record
    @default_cti_routine_record ||= CtiRoutine.first(:select => "web_cti_routines.id, web_cti_routines.value", :joins => "INNER JOIN web_groups_cti_routines_xref xref ON xref.cti_routine_id = web_cti_routines.id", :conditions => ["xref.default_cti_for_group = ? AND xref.group_id = ?", true, self.id])
  end
  
  def update_default_cti_routine(_default_cti_routine_id, _current_user)
    if (_current_user.member_of? 'Super User') && (!self.group_default)
      GroupCtiRoutineXref.update_all(["default_cti_for_group = ?", false], ["group_id = ? AND default_cti_for_group = ?", self.id, true])
      xref = GroupCtiRoutineXref.first(:conditions => {:group_id => self.id, :cti_routine_id => _default_cti_routine_id})
      xref.update_attributes(:default_cti_for_group => true, :modified_by => _current_user.login)
    else
      true
    end
  end
  
  def used_cti_routine_ids
    VlabelMap.all(:select => "DISTINCT wcr.id as cti_routine_id", :joins => "INNER JOIN web_cti_routines wcr ON racc_vlabel_map.cti_routine=wcr.value AND racc_vlabel_map.app_id=wcr.app_id", :conditions => ["racc_vlabel_map.app_id = ? AND racc_vlabel_map.vlabel_group = ?", self.app_id, self.name]).map { |vlm| vlm.cti_routine_id.to_i }
  end
  
  def has_mapped_dnises?
    nbr_mapped_dnises = VlabelMap.all(:conditions => ["app_id = ? AND (vlabel_group = ? OR vlabel_group = ?) AND (mapped_dnis is not null AND mapped_dnis <> '')", self.app_id, self.name, "#{self.name}_GEO_ROUTE_SUB"]).size
    nbr_mapped_dnises > 0 ? true : false
  end
  
  def display_cti_routine_field?
    grp_cti_routines = self.cti_routines
    !(grp_cti_routines.size == 1 && grp_cti_routines[0].value.to_i == 0)
  end
  
  def is_geo_route_default_group?
    self.group_default && self.category == 'b' && self.name == GEO_ROUTE_DEFAULT_GROUP_NAME
  end

  def self.groups_with_preroutes(app_id)
    #preroute_edit_config
    Group.
      from("web_groups as g").
      select("g.id, g.category, g.group_default, g.app_id, g.operation_id,
        g.display_name, g.show_display_name, g.position, g.name").
      joins("INNER JOIN racc_op op ON op.op_id = g.operation_id").
      where("g.app_id = ? AND g.group_default = ? AND op.preroute_enabled = ? AND show_display_name = ?", app_id, false, true, true).
      order("g.position").
      includes(:preroute_selection => :preroute_grouping)
  end
  
  def has_preroutes_on_vlabels
    #group_decorator
    preroutes = VlabelMap.select("DISTINCT preroute_group_id").in_group(8245,self.name)
    preroutes.delete_if {|x| x.preroute_group_id.nil? || x.preroute_group_id == 0}
  end
  
  def vlabels_in_use
    vlabel_list = {}
    company_config = CompanyConfig.find_by_app_id(self.app_id)
    vlabel_list[:default_survey] = company_config ? company_config.default_survey : nil
    vlabel_list[:divr] = DynamicIvr.find_all_in_divrs(self.app_id, "transfer_strings")
    vlabel_list[:routed_to] = VlabelMap.routed_to.for(self.app_id).map(&:vlabel)
    if ['b','x'].include?(self.category)
      vlabel_list[:transfer_map] = TransferMap.find_all_by_app_id(self.app_id).collect { |map| map.vlabel }
      vlabel_list[:geo_route] = self.is_geo_route_default_group? ? GeoRouteAniXref.select(:route_name).where(:app_id => self.app_id).map{ |gxref| gxref.route_name } : []
    	vlabel_list[:dequeue_label] = RaccRouteDestinationXref.all_dequeue_labels(self.app_id)
		elsif self.category == 'f'
      vlabel_list[:default_f] = Operation.current_f_default_vlabels(@app_id)
    end
    vlabel_list
  end

  private
  
  def limit_is_set
    self.category == 'f' && self.default_routes_filter == DEFAULT_ROUTE_FILTER_LIMIT
  end

end
