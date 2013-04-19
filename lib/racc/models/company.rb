class Company < ActiveRecord::Base
  self.table_name = "web_companies"
  self.primary_key = :app_id
  
  
  oath_keeper
  
  has_many :users, :foreign_key => :app_id, :primary_key => :app_id
  has_many :groups, :foreign_key => :app_id, :primary_key => :app_id
  has_many :settings, :foreign_key => :app_id, :primary_key => :app_id
  has_many :operations, :foreign_key => :app_id, :primary_key => :app_id
  has_many :recordeddnises, :foreign_key => :app_id, :primary_key => :app_id
  has_many :job_ids, :class_name => 'CompanyJobId'
  has_one :company_config, :foreign_key => :app_id
  has_and_belongs_to_many :user_groups, :foreign_key => :app_id, :uniq => true
  has_many :user_companies, :foreign_key => :app_id
  has_many :cache_url_xrefs, :foreign_key => :app_id
  has_many :cache_urls, :through => :cache_url_xrefs
  
  @racc_boolean = /(T|F)/

  validates_uniqueness_of :app_id
  validates_presence_of :name
  validates_numericality_of :max_destinations_for_time_segment, :max_preroutes_for_edit, :max_packages_for_route, :max_recording_length, :less_than_or_equal_to => 2147483647, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_format_of :recording_type, :with => /(P|R|D)/
  validates_numericality_of :full_call_recording_percentage, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100
  validates_format_of :split_full_recording, :with => @racc_boolean 
  validates_format_of :multi_channel_recording, :with => @racc_boolean
  validates_numericality_of :max_dynamic_ivr_actions, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_inclusion_of :queuing, :in => %w(inactive trial active)
  validates_numericality_of :cache_refresh_limit, :only_integer => true
  validates_presence_of :cache_url_xrefs
  validate :full_call_enabled_for_split, :split_is_set_for_multi_channel, :queuing_deactivation, :check_max_exits, :availability_of_route_to

  before_validation :nil_blanks, :normalize_stylesheet_name, :set_recording_settings
  before_save :update_recording_settings_for_vlabels, :update_modified_time_unix
  
  accepts_nested_attributes_for :company_config
  accepts_nested_attributes_for :job_ids, :reject_if => lambda { |j| j[:job_id].blank? }, :allow_destroy => true

  HUMANIZED_ATTRIBUTES = {
    :max_dynamic_ivr_actions => "Maximum Number of Actions",
    :"company_config.alternate_command_character" => "Alternate Command Character",
    :cache_url_xrefs => "Cache URLs"
  }
  
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  def queuing_inactive?
    'inactive' == self.queuing
  end
  
  def queuing_trial?
    'trial' == self.queuing
  end
  
  def queuing_active?
    'active' == self.queuing
  end
  
  def queuing_or_divr_active?
    'active' == self.queuing || self.display_dynamic_ivr
  end
  
  @@css_suffix_exp = /\.css/

  def non_defaut_retention_recording_days_rules
    RecordedDnis.where("app_id = ? and not i6 = ?", self.app_id, -1)
  end

  def nil_blanks
    self.logo_file_name = nil if self.logo_file_name.blank?
    self.stylesheet = nil if self.stylesheet.blank?
  end
  
  def normalize_stylesheet_name
    self.stylesheet.gsub!(@@css_suffix_exp, '') if self.stylesheet
  end

  def recording_enabled?
    self.company_config.recording_enabled == 'T'
  end
  
  def post_call_enabled?
    return !!Operation.first(:conditions => {:app_id => self.app_id, :post_call => 'T'})
  end

  def can_refresh_cache?
    #replace with configurable value
    return true if self.last_cache_refresh_on.nil?
    cache_time_left <= 0 
  end

  def cache_time_left
    future = self.last_cache_refresh_on + self.cache_refresh_limit
    future.to_i - Time.now.to_i
  end

  def update_vlabels_based_on_rec_rules
    vlabels_from_rules = RecordedDnis.select("parm_key").where(:app_id => self.app_id).map{ |rd| rd.parm_key }
    
    if vlabels_from_rules.size == 0
      VlabelMap.update_all(["full_call_recording_enabled = ?, full_call_recording_percentage = ?, split_full_recording = ?, multi_channel_recording = ?", "F", 0, self.split_full_recording, self.multi_channel_recording], 
        ["app_id = ?", self.app_id])
    else
      # Update vlabels with rules
      VlabelMap.update_all(["full_call_recording_enabled = ?, full_call_recording_percentage = ?, split_full_recording = ?, multi_channel_recording = ?", "M", 100, self.split_full_recording, self.multi_channel_recording], 
        ["app_id = ? AND vlabel in (?)", self.app_id, vlabels_from_rules])

      # Update vlabels without rules
      VlabelMap.update_all(["full_call_recording_enabled = ?, full_call_recording_percentage = ?, split_full_recording = ?, multi_channel_recording = ?", "F", 0, self.split_full_recording, self.multi_channel_recording], 
        ["app_id = ? AND vlabel not in (?)", self.app_id, vlabels_from_rules])
    end
  end

  # Validates the new maximum number of routing exits for time segments
  def ts_max_exits
    TimeSegment
    .select("ts.id as ts_id, count(rd.exit_id) as ts_count")
    .from("web_time_segments as ts")
    .joins("INNER JOIN web_routings as r ON ts.id = r.time_segment_id")
    .joins("INNER JOIN web_routing_destinations as rd ON r.id = rd.routing_id")
    .where("ts.app_id = ?", app_id)
    .group("ts.id").map(&:ts_count).max
  end

  def default_admin_report
    report = AdminReport.where("app_id = ? AND name = ?", self.app_id, AdminReport::DEFAULT_NAME)
    report ? report.first : AdminReport.create(:app_id => self.app_id, :name => AdminReport::DEFAULT_NAME)
  end

  def allows_route_to_vlabels?
    [ROUTE_TO_VLM, ROUTE_TO_ALL].include?(self.route_to_options)
  end

  def allows_route_to_media?
    [ROUTE_TO_MEDIA, ROUTE_TO_ALL].include?(self.route_to_options)
  end

  private
  
  def set_recording_settings
    if (c_config = self.company_config) && recording_settings_changed?
      case self.recording_type 
      when 'P'
        self.full_call_recording_enabled = (self.full_call_recording_percentage == 0 ? 'F' : 'T')
        c_config.defer_discard = 'F'
      when 'R'
        self.full_call_recording_enabled = 'M'
        self.full_call_recording_percentage = 100
        c_config.defer_discard = 'F'
      when 'D'
        self.full_call_recording_enabled = 'T'
        self.full_call_recording_percentage = 100
        c_config.defer_discard = 'T'
      end
    end
  end
  
  def update_recording_settings_for_vlabels
    if self.company_config && recording_settings_changed?
      if self.recording_type == 'R' && !RecordedDnis.wildcards?(self.app_id)
        update_vlabels_based_on_rec_rules
      else
        VlabelMap.update_all(["full_call_recording_enabled = ?, full_call_recording_percentage = ?, split_full_recording = ?, multi_channel_recording = ?", self.full_call_recording_enabled, self.full_call_recording_percentage.to_i, self.split_full_recording, self.multi_channel_recording], ["app_id = ?", self.app_id])
      end
    end
  end
  
  def recording_settings_changed?
    self.company_config.recording_enabled_changed? || self.recording_type_changed? || self.full_call_recording_enabled_changed? || self.full_call_recording_percentage_changed? || self.split_full_recording_changed? || self.multi_channel_recording_changed?
  end
  
  def split_is_set_for_multi_channel
    self.errors[:base] << ("Recordings must be saved as call legs if multiple recording channels are used.") if (self.multi_channel_recording == 'T') && (self.split_full_recording == 'F')
  end
  
  def full_call_enabled_for_split
    self.errors[:base] << ("Recordings must be enabled if recordings are saved as call legs") if (self.split_full_recording == 'T') && (self.full_call_recording_enabled == 'F')
  end
  
  def queuing_deactivation
    if queuing_inactive? or queuing_trial?
      destinations = Destination.only_queues(self.app_id)
      routed_dests = destinations.any? do |d|
        d.has_routing?
      end
      self.errors.add(:base, 'Queuing cannot be inactivated while active routes contain queuing destinations.') if routed_dests
    end
  end

  def update_modified_time_unix
    self.company_config.modified_time_unix = Time.now.to_i
  end
  
  # Validates the new maximum number of routing exits for time segments
  def check_max_exits
    max = ts_max_exits || 1

    if max_destinations_for_time_segment < max
      errors.add(:max_destinations_for_time_segment, "must be greater than or equal to #{max}, the maximum number of destinations on an already existing time segment")
    end
  end

  def availability_of_route_to
    if !allows_route_to_vlabels?
      vlabel_count = RoutingExit.for(app_id).routed_to("VlabelMap").count
      vlabel_count += RaccRouteDestinationXref.for(app_id).routed_to("VlabelMap").count
      vlabel_count += LabelDestinationMap.for(app_id).routed_to("VlabelMap").count
      errors.add(:route_to, "numbers/labels cannot be turned off. Some are in use.") if vlabel_count > 0
    end

    if !allows_route_to_media?
      prompt_count = RoutingExit.for(app_id).routed_to("MediaFile").count
      prompt_count += RaccRouteDestinationXref.for(app_id).routed_to("MediaFile").count
      prompt_count += LabelDestinationMap.for(app_id).routed_to("MediaFile").count
      errors.add(:route_to, "prompts cannot be turned off. Some are in use.") if prompt_count > 0
    end
  end
end
