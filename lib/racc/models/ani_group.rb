class AniGroup < ActiveRecord::Base
  self.table_name = 'racc_ani_group'
  self.primary_key = :ani_group_id
  
  
  oath_keeper

  before_validation :set_app_id
  
  validates_presence_of :name, :description, :app_id
  validates_uniqueness_of :name, :scope => :app_id
  validate :uniqueness_of_anis
  validate :uniqueness_across_geo_routes
  
  has_many :geo_route_ani_xrefs, :dependent => :destroy
  has_many :geo_route_groups, :through => :geo_route_ani_xrefs
  has_many :ani_maps, :dependent => :destroy
  
  accepts_nested_attributes_for :ani_maps, :reject_if => lambda { |a| a[:ani].blank? }, :allow_destroy => true

  def uniqueness_of_anis
    dupes = self.ani_maps.map(&:ani).duplicates
    errors.add(:base, "ANIs may only be used once. Duplicate ANIs: #{dupes.sort.join(', ')}") if dupes.any?
  end
    
  def uniqueness_across_geo_routes
    self.geo_route_groups.each do |geo_route|
      ani_groups = geo_route.ani_groups.where(AniGroup.arel_table[:ani_group_id].eq(self.ani_group_id).not)
      ani_groups.each do |ani_group|
        other_anis = ani_group.ani_maps.map(&:ani)
        dupes = (other_anis + self.ani_maps.map(&:ani)).duplicates
        
        if dupes.any?
          errors.add(:base, "Conflict in Geo-Route Group: #{geo_route.name}, ANI Group: #{ani_group.name} on ANIs #{dupes.sort.join(', ')}")
        end
      end
    end
  end
  
  private
    def set_app_id
      self.app_id ||= ThreadLocalHelper.thread_local_app_id
    end
end

class Array
  def duplicates
    inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}.keys
  end
end
