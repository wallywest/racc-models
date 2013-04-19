class Destination < ActiveRecord::Base 
  self.table_name = "racc_destination"
  self.primary_key = :destination_id
  
  
  oath_keeper
  
  @@dnis_suffix = /(\d+)$/
  DIVR_DESTINATION_PROPERTY = 'NETWORK_DIVR'
  QUEUE_DESTINATION_PROPERTY = 'NETWORK_QUEUE'
  DIVR_MESSAGE = "If this destination is of type #{DestinationProperty::DIVR_DESTINATION_PROPERTY}, please verify that a Dynamic IVR is attached to this destination."

  attr_protected :app_id
  attr_accessor :destination_name, :join_destination_name
  
  has_many :racc_route_destination_xrefs, :foreign_key => :destination_id
  has_many :racc_route_exception_destination_xrefs, :foreign_key => :destination_id
  has_many :racc_routes, :through => :racc_route_destination_xrefs
  has_one :dynamic_ivr_destination, :dependent => :destroy
  has_one :dynamic_ivr, :through => :dynamic_ivr_destination
  has_one :queue_configuration_destination, :foreign_key => :vcq_dnis, :primary_key => :destination, :dependent => :destroy
  has_many :label_mappings, :foreign_key => :mapped_destination_id, :class_name => "LabelDestinationMap", :dependent => :destroy
  has_many :exit_mappings, :foreign_key => :exit_id, :class_name => "LabelDestinationMap", :dependent => :destroy
  has_many :vlabels_using_mapping, :through => :label_mappings, :foreign_key => :vlabel_map_id, :source => :vlabel_map
  has_many :vlabels_using_exit, :through => :exit_mappings, :foreign_key => :vlabel_map_id, :source => :vlabel_map
  has_many :routing_exits, :as => :exit, :dependent => :destroy

  accepts_nested_attributes_for :queue_configuration_destination
  accepts_nested_attributes_for :dynamic_ivr_destination, :allow_destroy => true
  
  before_validation :set_app_id, :join_destination_name
  
  validate :destination_format
  validates_presence_of :destination, :destination_title, :destination_property_name, :app_id
  validates_uniqueness_of :destination, :scope => :app_id, :case_sensitive => false
  validate :destination_property_must_exist
  validates_format_of :destination_title, :with => /\A[\w\d\-\'\(\)\%\+\:\.\#\&\/]\Z|\A[\w\d\-\'\(\)\%\+\:\.\#\&\/][\w\d\-\' \(\)\%\+\:\.\#\&\/\\]{0,62}[\w\d\-\'\(\)\%\+\:\.\#\&\/]\Z/, :message => "may only include letters, numbers, underscores, dashes, apostrophes, parentheses, percentage signs, plus signs, pound signs, ampersands, forward slashes, backward slashes, colons, periods, and spaces.  You are limited to 64 characters and cannot have leading or trailing spaces."
  validates_length_of :destination, :maximum => 64, :allow_nil => true, :allow_blank => true

  after_save :remove_routing_exit_errors, :generate_routing_exit_errors

  scope :in_dli, lambda {|dli_value| where("destination_attr = :destination_attr AND destination LIKE :destination", {:destination_attr => 'D', :destination => "#{dli_value}+%"}) } 
  scope :only_divr, lambda {|app_id| where(:app_id => app_id, :destination_property_name => DIVR_DESTINATION_PROPERTY).includes(:dynamic_ivr).order(:destination) }
  scope :only_queues, lambda {|app_id| where(:app_id => app_id, :destination_property_name => QUEUE_DESTINATION_PROPERTY)}
  scope :searches, lambda {|app_id, term| where(["racc_destination.app_id = ? AND (destination LIKE ? OR destination_title LIKE ?)", app_id, "%#{term}%", "%#{term}%"])}
  
  scope :recently_updated, order('modified_time DESC').limit(5)
  scope :recently_updated_for, lambda { |app_id| recently_updated.where(:app_id => app_id) }

  scope :with_property, (lambda do
    dest_table = Destination.arel_table
    prop_table = DestinationProperty.arel_table

    name_clause = dest_table[:destination_property_name].eq(prop_table[:destination_property_name])
    app_clause = dest_table[:app_id].eq(prop_table[:app_id])

    properties = dest_table.join(prop_table).on(name_clause.and(app_clause)).join_sql

    joins(properties)
  end)

  scope :mapped, with_property.merge(DestinationProperty.mapped)
  scope :queues, with_property.merge(DestinationProperty.queues)
  scope :divrs, with_property.merge(DestinationProperty.divrs)

  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end

  #
  # NOTE: Since the racc_destination and racc_destination_property tables are not linked by a conventional
  # foreign key (i.e. destination_property_id), I (Courtnie) had to link back to the racc_destination_property
  # table with this method.  Using the above belongs_to just returned nil.
  #
  def destination_property
    DestinationProperty.find_by_app_id_and_destination_property_name(self.app_id, self.destination_property_name)
  end
  
  def destination_property_must_exist
    dest_prop = DestinationProperty.first(:conditions => {:app_id => self.app_id, :destination_property_name => self.destination_property_name})
    errors[:base] << ("Destination type must exist.") if dest_prop.nil?
  end
  
  def routed?
    racc_route_destination_xrefs.any?
  end
  
  def mappable?
    destination_property && destination_property.allows_mapping?
  end
  
  def mapped?
    label_mappings.any? || exit_mappings.any?
  end

  # Gets the Routes that are currently using this destination.
  def in_vlabel_maps
    db_length = ActiveRecord::Base.connection.adapter_name.upcase =~ /MYSQL2/ ? "LENGTH" : "LEN"
     VlabelMap.select("vlm.*").
      from("racc_vlabel_map vlm").
      joins("INNER JOIN web_groups g ON
        g.app_id = vlm.app_id AND
        g.name = 
        (CASE
          WHEN vlm.vlabel_group like '%_GEO_ROUTE_SUB' THEN LEFT(vlm.vlabel_group, (#{db_length}(vlm.vlabel_group)-14))
          ELSE vlm.vlabel_group
          END)
        INNER JOIN racc_route rr on rr.route_name = vlm.vlabel AND rr.app_id = vlm.app_id
        INNER JOIN racc_route_destination_xref as xref ON xref.route_id = rr.route_id
        INNER JOIN racc_destination as dest ON dest.destination_id = xref.destination_id").
      where("dest.destination_id = ? AND g.app_id = ? AND g.category IN (?,?) AND g.group_default = ?", self.destination_id, self.app_id, 'b', 'x', false).uniq
  end

  def in_vlabel_maps_default_groups
    VlabelMap.select("vlm.*, g.display_name").
      from("racc_vlabel_map vlm").
      joins("INNER JOIN web_groups g ON
        g.app_id = vlm.app_id AND
        g.name = vlm.vlabel_group
        INNER JOIN racc_route rr on rr.route_name = vlm.vlabel AND rr.app_id = vlm.app_id
        INNER JOIN racc_route_destination_xref as xref ON xref.route_id = rr.route_id
        INNER JOIN racc_destination as dest ON dest.destination_id = xref.destination_id").
      where("dest.destination_id = ? AND g.app_id = ? AND g.group_default = ?", self.destination_id, self.app_id, true)
  end

  # Gets the Front End number groups that are using this destination.
  def in_frontend_groups
    # groups = []
    # xrefs = self.racc_route_destination_xrefs
    
    # vlabels = self.racc_routes.map {|rr| rr.vlabel_map }
    # vlabels.compact!
    # vlabels.delete_if {|v| v.group.category != "f" || v.group.group_default == false}
    # groups = vlabels.map {|v| Operation.first(:conditions => {:app_id => v.app_id, :newop_rec => v.vlabel}).group }
    Group.all(:conditions => ["name IN 
                                (SELECT vlabel_group FROM racc_op WHERE newop_rec IN 
                                  (SELECT vlabel FROM racc_vlabel_map WHERE vlabel IN 
                                    (SELECT route_name FROM racc_route WHERE route_id IN 
                                      (SELECT route_id FROM racc_route_destination_xref WHERE app_id = :app_id AND destination_id = :id)
                                    AND app_id = :app_id)
                                  AND app_id = :app_id)
                                AND app_id = :app_id)
                              AND app_id = :app_id AND category = :category AND group_default = :group_default", {:id => self.id, :app_id => self.app_id, :category => 'f', :group_default => false}])
  end
    
  # Gets the Pre-Route groups that are using this destination.
  def in_preroute_groups
    PrerouteGroup.all(:joins => "inner join racc_route as route on route.route_name = racc_preroute_group.route_name and route.app_id = racc_preroute_group.app_id inner join racc_route_destination_xref as xref on xref.route_id = route.route_id inner join racc_destination as  dest on dest.destination_id = xref.destination_id",
                      :conditions => ["dest.destination_id = :dest_id", {:dest_id => self.destination_id}])
  end    
  
  def in_georoute_groups
    GeoRouteGroup.all(:conditions => ["geo_route_group_id IN 
                                        (SELECT geo_route_group_id FROM racc_geo_route_ani_xref WHERE route_name IN 
                                          (SELECT route_name FROM racc_route WHERE route_id IN 
                                            (SELECT route_id FROM racc_route_destination_xref WHERE destination_id = :id AND app_id = :app_id) 
                                          AND app_id = :app_id)
                                        AND app_id = :app_id) 
                                      AND app_id = :app_id", {:app_id => self.app_id, :id => self.id}])
  end
  
  def in_survey_groups
    SurveyGroup.all(:conditions => ["survey_vlabel IN 
                                      (SELECT route_name FROM racc_route WHERE route_id IN 
                                        (SELECT route_id FROM racc_route_destination_xref WHERE destination_id = :id and app_id = :app_id) AND app_id = :app_id) 
                                      AND app_id = :app_id", {:app_id => self.app_id, :id => self.id}])
  end
  
  # Find all Destinations with an app_id, and concatenate the destination and title to "destination:destination_title"
  def self.selects(dest, app_id)
    selects = self.where("app_id = ? and destination like ?", app_id, dest + "%").order("destination ASC").limit(10)
  end

  # Find all Destinations with an app_id, and concatenate the destination and title to "destination:destination_title"
  def self.selects_containing(app_id, dest)
    selects = self.where("app_id = ? and destination like ?", app_id, '%' + dest + '%').order("destination ASC").limit(10)
  end
  
  # Find all Destinations with an app_id, and concatenate the destination and title to "destination:destination_title"
  def self.title_selects(title, app_id)
    self.where("app_id = ? and destination_title like ?", app_id, title + "%").order("destination_title ASC").limit(10)    
  end
  
  def self.by_title(title, app_id)
    self.where("app_id = ? and destination_title = ?", app_id, title).order("destination ASC")
  end
  
  def self.search_routed(dest, app_id)
    all_dest = Destination.where("app_id = ? and destination like ?", app_id, '%' + dest + '%').
      joins("INNER JOIN (select distinct destination_id from racc_route_destination_xref) rdx ON racc_destination.destination_id = rdx.destination_id")
  end

  def self.for_autocomplete(app_id, phrase)
    find_valid(app_id, phrase)
  end
    
  def self.destination_verified_for_package(app_id, dest)
    find_valid(app_id, dest, true).size > 0
  end

  def self.by_destination(app_id, destination)
    @labels = []
    @destinations = Destination.where("app_id = ? AND destination LIKE ?", app_id, '%' + destination + '%')
    @destinations.each do |dest|
      @labels << dest.destination
    end
    @labels
  end
  
  def self.find_by_property_name(app_id, property_name, args={})
    dest_query = Destination.select("racc_destination.*, racc_destination_property.*").with_property.where(:app_id => app_id).merge(DestinationProperty.not_mapped)
    dest_query = dest_query.where(:destination_property_name => property_name) unless property_name == 'ALL'

    if args[:limit]
      dest_query = dest_query.limit(args[:limit]).order("racc_destination.modified_time DESC")
   else
      dest_query = dest_query.order(:destination)
    end

    dest_query.includes(:racc_route_destination_xrefs, :label_mappings, :exit_mappings)
  end
  
  def has_routing?
    self.racc_route_destination_xrefs.nil? || self.racc_route_destination_xrefs.length < 1 ? false : true
  end
  
  def self.title(destination, app_id)
    unless destination.nil? || destination.empty?
      Destination.find(app_id, destination).destination_title
    end
  end
  
  def dli
    dli = nil
    if self.destination_attr == 'D'
      dli_dnis = self.destination.split('+')
      dli = Dli.find_by_app_id_and_value(self.app_id, dli_dnis[0])
    end
    dli
  end
  
  def format_for_search
    if self.mappable?
      path_method = :edit_label_destination_map_path
      meta_key = :location
      type = "Location"
    else
      path_method = :destination_path
      meta_key = :destination
      type = "Destination"
    end
    values = {:name => self.destination_title, :type => type, :path => {:method => path_method, :ref => self}, :date => self.modified_time, :meta => { meta_key => self.destination}}
    
    class << values
      def path_to_search_result view
        view.send(self[:path][:method], self[:path][:ref])
      end
    end
    
    return values
  end
  
  def dnis
    destination =~ @@dnis_suffix
    return $1
  end
  
  def is_divr?
    self.destination_property_name == DIVR_DESTINATION_PROPERTY
  end
  
  def is_queue?
    self.destination_property_name == QUEUE_DESTINATION_PROPERTY
  end
  
  def total_routes_used_in
    Destination.
      select("DISTINCT rr.route_name").
      from("racc_destination d").
      joins("INNER JOIN racc_route_destination_xref xref ON xref.destination_id=d.destination_id INNER JOIN racc_route rr ON rr.route_id=xref.route_id").
      where("d.destination_id = ?", self.id).size
  end
  
  def routable?
    self.is_divr? ? !self.dynamic_ivr.nil? : true
  end
  
  def routings
    self.routing_exits.with_package.map(&:routing)
  end

  def update_divr(divr)
    attached_divr = self.dynamic_ivrs[0]
    self.dynamic_ivr_ids = divr.scan(/./)
    if attached_divr && attached_divr.destinations.size == 0 && divr.empty?
      attached_divr.save_state(DynamicIvr::STATE_ENABLED)
    end
  end

  def find_used_routes
   h = {}
   h[:divrs] = [self.dynamic_ivr]
   h[:vlabels] = self.in_vlabel_maps
   h[:mapped_vlabels] = self.vlabels_using_exit.
     select("racc_vlabel_map.*, racc_label_destination_map.mapped_destination_id AS location_id")
   h[:locations] = self.exit_mappings.
     where("vlabel_map_id is null").
     joins(:mapped_destination).
     select("racc_destination.destination as location, racc_destination.destination_id as location_id")

   h[:frontend_groups] = self.in_frontend_groups
   h[:preroute_groups] = self.in_preroute_groups
   h[:georoute_groups] = self.in_georoute_groups
   h[:survey_groups] = self.in_survey_groups
   h[:default_groups] = self.in_vlabel_maps_default_groups
   h[:routed] = self.routed?
   h
  end

  private

  def destination_format
    match_destination_to_validation_format if self.destination_property
  end
  
  def match_destination_to_validation_format
    format_name = self.destination_property.validation_format
    dvf = DestinationValidationFormat.find_by_name(format_name)
    
    if dvf
      expr = Regexp.new(dvf.regex)
      if expr.match(self.destination).nil?
        errors.add(:destination, dvf.error_message)
      end
    end
  end
  
  def join_destination_name
    if self.destination_name.class == Array && self.destination.blank?
      self.destination = self.destination_name.reduce {|a, obj| a.to_s + obj.to_s}
    end
  end
  
  def remove_routing_exit_errors
    error_message = "Destination #{self.destination} does not have a Dynamic IVR attached."
    RaccError.where(:error_message => error_message).destroy_all
  end
  
  def generate_routing_exit_errors
    error_message = "Destination #{self.destination} does not have a Dynamic IVR attached."

    if self.is_divr? and self.dynamic_ivr.nil?
      self.routings.uniq.each do |routing|
        routing.generate_error(error_message)
      end
    end
  end

  def self.find_valid(app_id, phrase, use_equals=false)
    destinations = Destination.select("racc_destination.destination_id, racc_destination.destination, racc_destination.destination_title, racc_destination.destination_property_name").
      joins("LEFT JOIN web_dynamic_ivrs_destinations xref ON racc_destination.destination_id=xref.destination_id LEFT JOIN web_dynamic_ivrs divr ON divr.id=xref.dynamic_ivr_id").
      where("racc_destination.app_id = :app_id", {:app_id => app_id}).
      order("racc_destination.destination")
    
    if use_equals
      destinations = destinations.where("(CASE WHEN (UPPER(racc_destination.destination) = :query) AND racc_destination.destination_property_name <> :divr_property THEN racc_destination.destination
         WHEN (UPPER(racc_destination.destination) = :query) AND racc_destination.destination_property_name = :divr_property AND divr.state = :active_state THEN racc_destination.destination
         END) IS NOT NULL", {:query => phrase.upcase, :divr_property => DIVR_DESTINATION_PROPERTY, :active_state => "Active"})
    else
      destinations = destinations.where("(CASE WHEN (UPPER(racc_destination.destination) LIKE :query OR UPPER(racc_destination.destination_title) LIKE :query) AND racc_destination.destination_property_name <> :divr_property THEN racc_destination.destination
         WHEN (UPPER(racc_destination.destination) LIKE :query OR UPPER(racc_destination.destination_title) LIKE :query) AND racc_destination.destination_property_name = :divr_property AND divr.state = :active_state THEN racc_destination.destination
         END) IS NOT NULL", {:app_id => app_id, :query => "%#{phrase.upcase}%", :divr_property => DIVR_DESTINATION_PROPERTY, :active_state => "Active"})
    end  
    
    destinations
  end
  
end
