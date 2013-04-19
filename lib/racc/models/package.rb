class Package < ActiveRecord::Base
  self.table_name = "web_packages"

  oath_keeper :meta => Proc.new {|t| t.meta_data}, :version => true
  
  @@profile_class = Profile #get a copy of the original Profile due to namespace conflict with TimezoneConversion
  
  include TimezoneConversion

  belongs_to :vlabel_map
  belongs_to :company, :foreign_key => :app_id
  has_many :profiles, :inverse_of => :package
  has_many :racc_errors

  attr_accessor :direct_route
  accepts_nested_attributes_for :profiles, :allow_destroy => true

  before_validation :set_app_id
  after_update :generate_package_errors
  
  validates_presence_of :name, :description, :app_id
  
  HUMANIZED_ATTRIBUTES = {
    :"profiles.time_segments.routings.routing_exits.base" => "", 
    :"profiles.time_segments.routings.routing_exits.destination" => "Destination",
    :"profiles.time_segments.routings.routing_exits.dequeue_label" => "Dequeue",
    :"profiles.time_segments.routings.routing_exits.exit_id" => "Exit",
    :"profiles.time_segments.routings.routing_exits.package" => "Package"
  }
  
  scope :for, lambda {|app_id| where(:app_id => app_id)}
  scope :activated, where(:active => true)
  scope :starts_with, lambda {|term| where('upper(name) like upper(?)', "#{term}%")}
  scope :ordered, order('active desc, updated_at desc')
  scope :with_tree, includes({:profiles => {:time_segments => {:routings => {:routing_exits => :exit}}}})

  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end

  def self.auditable_search_field; :name; end

  def audit_description
    "Package #{name}"
  end
  
  def audit_name
    name
  end
  
  def inactive?
    return !self.active?
  end
  
  DAYS = {
    'sun' => 'Sunday',
    'mon' => 'Monday',
    'tue' => 'Tuesday',
    'wed' => 'Wednesday',
    'thu' => 'Thursday',
    'fri' => 'Friday',
    'sat' => 'Saturday'
  }
  
  def generate_package_errors
    delete_all_package_errors
    
    non_destroyed_profiles = profiles.select {|p| not p.marked_for_destruction?}.compact
    
    check_day_coverage unless non_destroyed_profiles.empty?

    non_destroyed_profiles.each do |profile|
      profile.check_time_segment_set_coverage_full_day(0, 0) if profile.time_segments.any?
      
      non_destroyed_time_segments = profile.time_segments.select {|ts| not ts.marked_for_destruction?}.compact
      
      non_destroyed_time_segments.each do |time_segment|
        time_segment.check_routing_set_percent_is_100 if time_segment.routings.any?
        
        non_destroyed_routings = time_segment.routings.select {|r| not r.marked_for_destruction?}.compact
        
        non_destroyed_routings.each do |routing|
          routing.check_routing_exits_are_valid if routing.routing_exits.any?
        end
      end
    end
  end

  # Delete all of the racc errors related to the profile set.
  def delete_profile_set_errors
    RaccError.delete_all(["package_id = ? and profile_id = -1 and time_segment_id = -1 and routing_id = -1", self.id])
  end
  
  # Inserts packages and exception packages into the Racc Platfrom.
  # The package and all children objects are read and then written
  # Racc Platform as logic dictates.
  def insert_to_racc(current_login='racc_admin')
    if activation_allowed?
      DestroyRoute.destroy(vlabel_map.vlabel, vlabel_map.app_id)
      self.insert_to_racc_utc
    end
  end

  def activation_allowed?
    racc_errors.empty? && exits_valid?
  end

  def exits_valid?
    if has_queuing_exits? && company.queuing_inactive?
      errors.add(:base, I18n.t('errors.messages.queuing_deactivated'))
      return false
    else
      return true
    end
  end

  def has_queuing_exits?
    exits.any? do |e|
      e.is_a?(Destination) && e.is_queue?
    end
  end

  def time_segments
    profiles.map(&:time_segments).flatten
  end

  def routings
    time_segments.map(&:routings).flatten
  end

  def routing_exits
    routings.map(&:routing_exits).flatten
  end

  def exits
    routing_exits.map(&:exit)
  end

  # Check all of the profiles to see if there are days of the week
  # that are not accounted for in any profile or accounted for twice.
  # If the day is empty or the day has 2 profiles set for it create
  # an error.
  def check_day_coverage
    #Create a hash to count the day-of-week settings from all profiles
    week = {}; DAYS.each { |d,name| week[d] = 0 }

    # Only check profiles that are not marked for destruction
    non_destroyed_profiles = profiles.select {|p| not p.marked_for_destruction?}.compact
    
    #count 'em
    non_destroyed_profiles.each do |p|
      DAYS.each {|d,name| week[d] += 1 if p.send(d) }
    end

    week.each do |day, count|
      if count == 0
        create_profile_set_error("<b>#{DAYS[day]}</b>&nbsp; is not set")
      elsif count > 1
        create_profile_set_error("<b>#{DAYS[day]}</b>&nbsp; is set in multiple profiles")
      end
    end
  end
  
  # Writes a racc error message that will include the package id
  def create_profile_set_error(err)
    r_error = RaccError.new
    r_error.error_message=err
    racc_errors << r_error
  end
  
  # Instantiate a shallow copy of this package with a new name. The
  # new package will be an unsaved record and will not include the
  # set of associations that this package contains.
  def copy
    obj = self.dup
    obj.attributes = {
      :name => "Copy of #{name}",
      :active => false,
      :created_at => nil,
      :updated_at => nil
    }
    obj
  end
  
  # Instantiate a deep copy of this package. The new package will be
  # an unsaved record and will hold the same tree of profiles, time
  # segments, routings, and destinations as this package.
  def deep_copy
    @new_package = self.copy
    self.profiles.each do |profile|
      @new_profile = profile.copy
      @new_package.profiles << @new_profile
      
      profile.time_segments.each do |ts|
        @new_time_segment = ts.copy
        @new_profile.time_segments << @new_time_segment
        
        ts.routings.each do |routing|
          @new_routing = routing.copy
          @new_time_segment.routings << @new_routing
          
          routing.routing_exits.each do |re|
            #THIS IS GROWING EXPONENTIALLY
            @new_routing_exit = re.copy
            @new_routing.routing_exits << @new_routing_exit
          end
        end
      end
    end
    
    @new_package
  end
  
  def without_nested_auditing
    ::Profile.without_auditing do
      TimeSegment.without_auditing do
        ::Routing.without_auditing do
          yield
        end
      end
    end
  end
        
  # Returns true if any profile has an empty time segment
  # otherwise false
  def any_empty_time_segment?
    self.empty?(self, "time_segments", false)
  end
  
  # Returns true if any time segment has any routing set that is empty 
  def any_empty_routing?
    self.empty?(self, "routings", false)
  end
  
  def any_empty_exit?
    self.empty?(self, "exits", false)
  end
  
  def any_empty_exit_id?
    no_exit_id = false
    self.profiles.each do |profile|
      profile.time_segments.each do |ts|
        ts.routings.each do |routing|
          routing.routing_exits.each do |re|
            if re.exit_id.nil?
              no_exit_id = true
            end
          end
        end
      end
    end
    no_exit_id
  end
  
  # This recursive method will tell you if any of the objects are empty in a given tree given a certain depth 
  # 1.  Stop as soon as any children are empty and recurse back up
  # 2.  Get all the has_many assocations for the active record object passed in the first argument
  # 3.  Only check one of the four associations in our data tree (profiles, time_segments, routings, or destinations)
  # 4.  If the children are empty return true
  # 5.  If we're on the start class return that value
  # 6.  Otherwise interegate all children of the start class using the recursive call
  # 7.  Return the status
  def empty?(startObject, stopClass, status)
    unless status
      startObject.class.reflect_on_all_associations(:has_many).each do |assoc|  
        if ['profiles','time_segments','routings','routing_exits'].include?(assoc.name.to_s)
          if startObject.send(assoc.name).empty?
            status = true
          elsif stopClass == assoc.name.to_s
            status = startObject.send(assoc.name).empty?
          else 
            startObject.send(assoc.name).each do |obj|
              if self.empty?(obj,stopClass, false)
                status = true
              end
            end
          end
        end
      end
    end
    status
  end
  
  def error_profiles?
    self.racc_errors.on_profiles.any?
  end
  
  def error_time_segments?
    self.racc_errors.on_time_segments.any?
  end
  
  def error_routings?
    self.racc_errors.on_routings.any?
  end
  
  def error_routing_exits?
    self.racc_errors.on_routing_exits.any?
  end
  
  def self.active_package_names_containing(name, app_id)
    packages = self.find_all_by_app_id(app_id, 
                                      :conditions => ["active = ? and name like ?", true, "%#{name}%"],
                                      :joins => :vlabel_map)

    # return only unique
    packages.map {|p| p.name}.uniq
  end
  
  def activate
    vlm = self.vlabel_map
    grp = vlm.group
    
    vlm.deactivate_all_packages
    self.active = true
    
    if self.save && (grp.group_default == true && grp.category == 'f')
      add_new_default_route_to_filters(vlm)
    end
  end
  
  def valid_divr_destinations?
    all_valid = true
    divr_dests = Destination.
      where("destination_id in (select exit_id from web_routing_destinations where id in (?) AND exit_type = 'Destination')",self.routing_exits_ids).
      where(:destination_property_name => Destination::DIVR_DESTINATION_PROPERTY)

    if divr_dests.size > 0
      divr_dests.each do |dd|
        all_valid = false if dd.dynamic_ivr == nil
      end
    end
    all_valid
  end
  
  def empty_components?
    self.error_profiles? || self.profiles.empty? || self.any_empty_time_segment? || self.error_time_segments? || self.any_empty_routing? || self.error_routings? || self.any_empty_exit? || self.any_empty_exit_id? || self.error_routing_exits?
  end
  
  def activate_active_package(updated_attrs, user_login, backend_number)
    activated = false
    msgs = ""
    
    begin
      ActiveRecord::Base.transaction do
        self.attributes = updated_attrs
        if self.save
          self.reload
          self.set_tz_profiles
          if self.insert_to_racc(user_login)
            backend_number.update_modified_time(user_login)
            msgs = "Package was successfully updated and activated."
            activated = true
          else
            msgs = "An error occurred while updating this package.  This package was not updated or activated."
            logger.error "Failed to update ACTIVE package #{self.id} - #{self.name}"
            raise ActiveRecord::Rollback, "Insert into racc_route table failed."
          end
        else
          msgs = self.errors.full_messages
        end
      end
    rescue => e
      msgs = "An error occurred while updating this package.  This package was not updated or activated."
      logger.error "Failed to update ACTIVE package #{self.id} - #{self.name}.  Error is:  #{e.inspect}"      
    end    
    
    [activated, msgs]
  end

  def meta_data
    Package.select("t1.id, t1.name, t1.active, t2.vlabel, t3.display_name, t3.category, t3.group_default").
    from("web_packages as t1").
    joins("LEFT JOIN racc_vlabel_map as t2 ON t1.vlabel_map_id = t2.vlabel_map_id").
    joins("LEFT JOIN web_groups as t3 ON REPLACE(t2.vlabel_group, '_GEO_ROUTE_SUB', '') = t3.name").
    where('t1.id' => self.id).first.attributes
  end


  def delete_all_package_errors
    RaccError.delete_all(["package_id = ?", self.id])
  end

  def routing_exits_ids
    serialized_ids(:routing_exits).map{|x| x[:id]}
  end

  def routings_ids
    serialized_ids(:routings).map{|x| x[:id]}
  end

  def time_segments_ids
    serialized_ids(:time_segments).map{|x| x[:id]}
  end

  def profiles_ids
    serialized_ids(:profiles).map{|x| x[:id]}
  end

  def serialized_ids(key)
    serialized[key] ||= []
  end

  def serialized
    @pjson ||= PackageSerializer.new(self).as_json
  end

  def direct_route?
    "yes" == self.direct_route
  end

  private
  
  def add_new_default_route_to_filters(vlm)
    eligible_groups = Group.where(["app_id = ? AND category = ? AND default_routes_filter = ? AND group_default = ?", self.app_id, 'f', Group::DEFAULT_ROUTE_FILTER_LIMIT_AND_NEW, false])
    eligible_groups.each do |grp|
      grp.default_routes << vlm
    end
  end
end
