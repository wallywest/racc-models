class GeoRouteGroup < ActiveRecord::Base
  self.table_name = 'racc_geo_route_group'
  self.primary_key = :geo_route_group_id
  
  
  oath_keeper
  
  validates_presence_of :name, :description
  validates_uniqueness_of :name, :scope => :app_id
  validate :uniqueness_of_ani_groups
  validate :uniqueness_of_anis
  
  has_many :geo_route_ani_xrefs, :dependent => :destroy
  has_many :ani_groups, :through => :geo_route_ani_xrefs

  accepts_nested_attributes_for :geo_route_ani_xrefs, :allow_destroy => true
  attr_accessible :geo_route_ani_xrefs_attributes, :name, :description, :app_id

  scope :for, lambda {|app_id| where(:app_id => app_id)}

  HUMANIZED_ATTRIBUTES = {:"geo_route_ani_xrefs.route_name" => "ANI Group Package"}
  
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def uniqueness_of_ani_groups
    ani_group_ids = geo_route_ani_xrefs.map(&:ani_group_id)
    if ani_group_ids.uniq.length < ani_group_ids.length
      errors[:base] << "Cannot use the same ANI Group more than once"
    end
  end
  
  def uniqueness_of_anis
    conflicting_pairs = []
    ani_group_list = geo_route_ani_xrefs.map(&:ani_group)
    ani_group_list.each_with_index do |ani_group, i|
      other_ani_groups = ani_group_list[(i+1)..-1]
      other_ani_groups.each do |other_ani_group|
        conflicts = (ani_group.ani_maps.map(&:ani)) & (other_ani_group.ani_maps.map(&:ani))
        conflicting_pairs << "#{ani_group.name} and #{other_ani_group.name}" unless conflicts.empty?
      end
    end
    
    unless conflicting_pairs.empty?
      errors[:base] << "Conflicting ANI Groups: #{conflicting_pairs.join(', ')}"
    end
  end
  
  def delete_anis(ani_xref_params)
    ani_xref_params.each {|key, value|
      if value[:_destroy] == '1'
        self.geo_route_ani_xrefs.find(value[:id]).delete if value[:id]
      end}
  end
  
  def self.saved_anis(ani_xref_params)
    saved_anis = {}
    ani_xref_params.each {|key, value|
      if value[:_destroy] != '1'
        saved_anis[key] = value
      end}
    return saved_anis
  end
end
