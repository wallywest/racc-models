class VlabelMap < ActiveRecord::Base
  self.table_name = "racc_vlabel_map"
  self.primary_key = :vlabel_map_id

  
  oath_keeper :meta => [[:group,:display_name],[:preroute_group,:group_name],[:geo_route_group,:name],[:survey_group,:name]]

  belongs_to :preroute_group
  belongs_to :survey_group
  belongs_to :geo_route_group
  belongs_to :company, :foreign_key => :app_id
  has_many :packages
  has_many :racc_routes, :finder_sql => proc {"select * from racc_route where racc_route.app_id=#{app_id} and racc_route.route_name='#{vlabel}'"}
  has_many :group_default_routes, :dependent => :destroy
  has_many :many_to_one_groups, :through => :group_default_routes, :source => :vlabel_map
  has_many :routing_exits, :as => :exit, :dependent => :destroy
  has_many :racc_route_destination_xrefs, :as => :exit, :foreign_key => "destination_id"
  has_many :mapped_dests, :foreign_key => :vlabel_map_id, :class_name => "LabelDestinationMap"
  has_one :preroute_selection

  before_validation :set_app_id, :empty_string_to_nil_for_mapped_dnis
  before_validation :set_recording_settings, :on => :create

  validates_format_of :vlabel, :with => /\A[\w-][\w@\/:. \[\]]{0,30}[\w@\/:.\[\]]\Z/, :message => "must start with a number, letter, or underscore.  Must only contain letters, numbers, @, :, /, ., [, ], and _'s.  Must be less than 32 characters.", :unless => :is_frontend_number
  validates_format_of :mapped_dnis, :with => /\A[\d]{4,14}\Z/, :allow_nil => true, :message => "must be a number between 4 and 14 digits in length"
  validates_presence_of :full_call_recording_percentage
  validates_uniqueness_of :vlabel, :scope => :app_id
  validates_length_of :description, :maximum => 500, :allow_nil => true, :message => 'may not exceed 500 characters, including spaces'  
  validate :existence_of_operation
  validate :format_of_f_num, :if => :is_frontend_number
  
  attr_accessor :direct_route
  attr_protected :app_id

  self.per_page = 1000 # Number of f numbers to display per page

  HUMANIZED_ATTRIBUTES = {:vlabel => "Number/Label", :mapped_dnis => "Mapped DNIS"}

  scope :in_routes, where("vlabel IN (SELECT route_name FROM racc_route WHERE racc_route.app_id = racc_vlabel_map.app_id AND racc_route.route_name = racc_vlabel_map.vlabel)")
  scope :routed_to, joins(:racc_route_destination_xrefs).merge(RaccRouteDestinationXref.routed_to("VlabelMap"))
  scope :in_group, (lambda do |app_id, names| 
    names = [names] unless names.is_a?(Array)
    geoed_names = names.map{|n| [n, "#{n}_GEO_ROUTE_SUB"]}.flatten
    where("racc_vlabel_map.app_id = ? AND racc_vlabel_map.vlabel_group in (?)", app_id, geoed_names)
  end)
  scope :with_location, (lambda do |loc_id|
    vlm = VlabelMap.arel_table
    ldm = LabelDestinationMap.arel_table

    vlm_id_clause = vlm[:vlabel_map_id].eq(ldm[:vlabel_map_id])
    mapped_dest_id_clause = ldm[:mapped_destination_id].eq(loc_id)

    vlm_and_ldm = vlm.join(ldm, Arel::Nodes::OuterJoin).on(vlm_id_clause.and(mapped_dest_id_clause)).join_sources

    joins(vlm_and_ldm)
  end)
  scope :with_group, (lambda do
    db_length = ActiveRecord::Base.connection.adapter_name.upcase =~ /MYSQL2/ ? "LENGTH" : "LEN"
    joins("INNER JOIN web_groups ON web_groups.app_id = racc_vlabel_map.app_id AND 
      web_groups.name = (CASE
        WHEN racc_vlabel_map.vlabel_group LIKE '%GEO_ROUTE_SUB' THEN LEFT(racc_vlabel_map.vlabel_group, (#{db_length}(racc_vlabel_map.vlabel_group)-14))
        ELSE racc_vlabel_map.vlabel_group
      END)")
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
  scope :for, lambda {|app_id| where(app_id: app_id)}
  scope :matches, lambda {|term| where('vlabel like ?', "%#{term}%")}
  scope :search_for, lambda {|app_id, term| matches(term).for(app_id)}
  scope :search_for_exact, lambda {|app_id, term| where(vlabel: term).for(app_id)}

  def geo_route_ani_xrefs
    GeoRouteAniXref.where(:app_id => app_id, :route_name => vlabel)
  end
  
  def existence_of_operation
    op = Operation.first(:conditions => {:app_id => self.app_id, :vlabel_group => self.vlabel_group})
    errors[:base] << ("Operation must exist") if op.nil?
  end

  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  def update_geo_routing(geo_route_id = 0)
    self.geo_route_group_id = geo_route_id
    op = Operation.first(:conditions => {:app_id => self.app_id, :vlabel_group => self.vlabel_group})
    unless (geo_route_group_id.to_i <= 0) ^ (op.operation == Operation::ONE_TO_ONE_GEO_OP)
      current_operation = Operation.first(:conditions => {:app_id => self.app_id, :vlabel_group => self.vlabel_group})
      self.vlabel_group = VlabelMap.toggle_vlabel_group(current_operation, Operation::ONE_TO_ONE_GEO_OP, self.vlabel_group, self.app_id)
    end
  end

  @@geo_route_vlabel_group = /(.+)_GEO_ROUTE_SUB$/

  def self.toggle_vlabel_group(current_operation, geo_route_op, group_name, app_id)
    if current_operation.operation == geo_route_op
      current_operation.vlabel_group =~ @@geo_route_vlabel_group
      if target_vlabel_group = $1
        return target_vlabel_group
      else
        raise Exception.new("Operation is set to #{geo_route_op}, but the vlabel_group is not *_GEO_ROUTE_SUB")
        Rails.logger.error "Operation is set to #{geo_route_op}, but the vlabel_group is not *_GEO_ROUTE_SUB for #{self.inspect}"
      end
    else
      target_vlabel_group = "#{group_name}_GEO_ROUTE_SUB"
      unless Operation.exists?(:vlabel_group => target_vlabel_group, :app_id => app_id)
        target_operation = current_operation.dup
        target_operation.vlabel_group = target_vlabel_group
        target_operation.operation = geo_route_op
        target_operation.save!
      end
      return target_vlabel_group
    end
  end

  def is_frontend_number
    grp = self.group
    grp.category == 'f' and grp.group_default == false if grp
  end
  
  DB_LENGTH_FUNC = ActiveRecord::Base.connection.adapter_name.upcase == 'MYSQL2' ? "LENGTH" : "LEN"
  
  scope :call_legs, lambda { |app_id|
    where("racc_vlabel_map.app_id = ? AND web_groups.category IN (? , ? , ?) AND web_groups.group_default = ?", app_id, 'f', 'b', 'x', false).
    joins("INNER JOIN web_groups ON web_groups.app_id = racc_vlabel_map.app_id AND 
      web_groups.name = (
      CASE WHEN racc_vlabel_map.vlabel_group LIKE '%_GEO_ROUTE_SUB'
      THEN LEFT(racc_vlabel_map.vlabel_group, (#{DB_LENGTH_FUNC}(racc_vlabel_map.vlabel_group) - 14))
      ELSE racc_vlabel_map.vlabel_group END)").
    select("racc_vlabel_map.*, web_groups.id as group_id, web_groups.display_name as group_display_name")
  }
  scope :with_packages, includes(:packages)

  def format_for_search
    values = {:name => self.vlabel, :type => self.group_display_name, :date => self.modified_time}
    if self.is_frontend_number
      values.merge!({:path => {:method => :frontend_group_path, :ref => self}})
      def values.path_to_search_result view
        view.send(self[:path][:method], self[:path][:ref].group_id)
      end
    else
      values.merge!({:path => {:method => :entry_group_backend_number_packages_path, :ref => self}, :meta => {:number_of_packages => self.packages.size}})
      def values.path_to_search_result view
        view.send(self[:path][:method], self[:path][:ref].group_id, self[:path][:ref])
      end
    end
    
    return values
  end
  
  # Using this instead of belongs_to b/c it doesn't work
  def group
    case self.vlabel_group
    when @@geo_route_vlabel_group
      group_name = $1
    else
      group_name = self.vlabel_group
    end
    Group.find_by_app_id_and_name(self.app_id, group_name)
  end

  def exists?(app_id)
    @vlabels ||= VlabelMap.where("app_id = ? ", app_id).collect { |c| c.vlabel }.uniq
    @vlabels.include?(self.vlabel)
  end

  def self.get(app_id, vlabel, group)
    VlabelMap.find_by_app_id_and_vlabel_and_vlabel_group(app_id, vlabel, group)
  end

  def self.delete_translation_route(vlabel_map_id)
    begin

      vlabel_map = VlabelMap.find(vlabel_map_id)
      racc_route = RaccRoute.find_by_route_name_and_app_id(vlabel_map.vlabel, vlabel_map.app_id)
      xrefs = RaccRouteDestinationXref.where("route_id = ? and app_id = ?", racc_route.route_id, racc_route.app_id)

      xrefs.each do |xref| xref.destroy end
      racc_route.destroy
      vlabel_map.destroy

    rescue => e
      logger.error e.to_s
      return false
    end

    return true

  end
  
  def self.new_bnumber_vlabel(args = {})
    # NOTE:  The cti routine gets set in the gui, so the cti routine needs
    # to be passed in when this is called.  This function looks like it's only
    # called in scripts.
    @vlabel_map = VlabelMap.new
    @vlabel_map.app_id = args[:app_id]
    @vlabel_map.vlabel = args[:bnumber_value]
    @vlabel_map.vlabel_group = args[:bnumber_vlabel_group]
    @vlabel_map.description = args[:description]
    @vlabel_map.cti_routine = 3
    @vlabel_map.modified_time = Time.now
    @vlabel_map.full_call_recording_enabled = "F"
    @vlabel_map.full_call_recording_percentage = 0
    @vlabel_map.modified_by = args[:user_login]
    
    @vlabel_map
  end
  
  def self.create_bnumber_vlabel(args = {})
    VlabelMap.new_bnumber_vlabel(args).tap { |v| v.save }
  end
  
  class << self
    alias :bnumber_vlabel :create_bnumber_vlabel
  end
  
  def destroy_all
    DestroyRoute.destroy(vlabel, app_id)
    self.packages = []
    self.save
    self.destroy
  end
  
  # Returns an array of active packages; there should only be one but
  # this will account for any potential problems
  def active_packages(_packages=nil)
    _packages ||= self.packages
    _packages.select{|p| p.active == true}
  end
  
  # Deactivates any active packages
  def deactivate_all_packages
    active_packages.each do |package| 
      package.active = false
      package.save
    end
  end
  
  def self.with_routes(app_id, vlabel)
    VlabelMap.first(:conditions => {:app_id => app_id, :vlabel => vlabel},
                    :joins => "INNER JOIN racc_route ON racc_route.app_id = racc_vlabel_map.app_id AND racc_route.route_name = racc_vlabel_map.vlabel")
  end
  
  def copy_existing_active(package_id)
    @existing = Package.find(package_id, :conditions => {:app_id => self.app_id, :active => true})
    
    ActiveRecord::Base.transaction do
      @package = @existing.deep_copy
      @package.active = false
      self.packages << @package
      @package.save
    end
  end
  
  def preroute_group_changed?(new_preroute_group_id)
    self.preroute_group_id.to_s != new_preroute_group_id.to_s
  end
  
  def survey_group_changed?(new_survey_group_id)
    self.survey_group_id.to_s != new_survey_group_id.to_s
  end
  
  def update_modified_time(current_user)
    self.update_attributes({:modified_time => Time.now, :modified_by => current_user})
  end
  
  def self.divr_transfer_strings(_app_id, _search_param, _exact_match=false)
    if _exact_match
      param_comparison = "="
    else
      param_comparison = "LIKE"
      _search_param = "%#{_search_param}%"
    end
    
    VlabelMap.
      select("DISTINCT vlm.vlabel AS result").
      from("racc_vlabel_map vlm").
      joins("JOIN racc_route rr ON rr.app_id=vlm.app_id AND rr.route_name=vlm.vlabel 
        JOIN web_groups grp ON grp.app_id=vlm.app_id AND grp.name=vlm.vlabel_group").
      where("vlm.app_id = :app_id 
        AND vlm.vlabel #{param_comparison} :search_param 
        AND grp.group_default = :is_group_default", 
        {:app_id => _app_id, :search_param => _search_param, :is_group_default => false}).
    map{ |vlm| vlm.result }.compact
  end
  
  def actual_group_name
    self.vlabel_group =~ /(.+)_GEO_ROUTE_SUB$/ ? $1 : self.vlabel_group
  end
  
  def self.with_mapped_dests(app_id, group_names, location_id)
    VlabelMap.
      with_group.
      with_location(location_id).
      with_destination_exits.
      with_vlabelmap_exits.
      with_mediafile_exits.
      select("racc_vlabel_map.vlabel_map_id AS vlm_id,
              racc_vlabel_map.*, 
              racc_label_destination_map.id AS ldm_id, 
              racc_label_destination_map.*,
              web_groups.display_name AS grp_name,
              (CASE
                WHEN racc_label_destination_map.exit_type = 'Destination' THEN d_exit.destination
                WHEN racc_label_destination_map.exit_type = 'VlabelMap' THEN v_exit.vlabel
                WHEN racc_label_destination_map.exit_type = 'MediaFile' THEN m_exit.keyword END) AS exit_label,
              (CASE
                WHEN racc_label_destination_map.exit_type = 'Destination' THEN 'Destination'
                WHEN racc_label_destination_map.exit_type = 'VlabelMap' THEN 'Number/Label'
                WHEN racc_label_destination_map.exit_type = 'MediaFile' THEN 'Prompt' END) AS exit_type_pretty").
      in_group(app_id, group_names).
      order(:vlabel)
  end

  def direct_route?
    "yes" == self.direct_route
  end
  
  private

  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end

  def set_recording_settings
    company = Company.find(self.app_id)
    self.split_full_recording = (company.split_full_recording || 'F')
    self.multi_channel_recording = (company.multi_channel_recording || 'F')
    
    if company.recording_type == 'R'
      if RecordedDnis.has_rule_for_vlabel?(self.app_id, self.vlabel)
        self.full_call_recording_enabled = 'M'
        self.full_call_recording_percentage = 100
      else
        self.full_call_recording_enabled = 'F'
        self.full_call_recording_percentage = 0
      end
    else
      self.full_call_recording_enabled = (company.full_call_recording_enabled || 'F')
      self.full_call_recording_percentage = (company.full_call_recording_percentage || 0)
    end
  end
  
  def empty_string_to_nil_for_mapped_dnis
    self.mapped_dnis = nil if self.mapped_dnis == ''
  end
  
  def format_of_f_num
    # Can't use the built in validation b/c the humanized vlabel needs to be called
    # a "Number" for f numbers and "Number/Label" for b numbers
    unless self.vlabel =~ /^[\d]{10}$/
      errors[:base] << ("Number must be exactly 10 digits")
    end
  end
end
