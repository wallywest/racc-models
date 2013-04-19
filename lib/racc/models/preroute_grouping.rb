class PrerouteGrouping < ActiveRecord::Base
  self.table_name = :web_preroute_groupings
  
  
  oath_keeper
  
  ALL_GROUPING = 'All'
  
  has_many :preroute_grouping_xrefs, :dependent => :destroy
  has_many :preroute_groups, :through => :preroute_grouping_xrefs
  has_many :preroute_selections, :foreign_key => :preroute_grouping_id
  
  validates_presence_of :name, :temp_preroute_group_ids
  validates_length_of :name, :maximum => 64
  validates_uniqueness_of :name, :scope => :app_id
  
  after_save :save_preroute_groups
  
  # Temporarily holds the pre-route group ids.  Needed to do this b/c we needed
  # to save the pre-route grouping before any associations could be saved
  attr_accessor :temp_preroute_group_ids  
  
  HUMANIZED_ATTRIBUTES = {:temp_preroute_group_ids => "Pre-Routes"}

  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  private
  
  def save_preroute_groups
    self.preroute_group_ids = temp_preroute_group_ids
  end
end
