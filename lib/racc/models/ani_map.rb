class AniMap < ActiveRecord::Base
  self.table_name = 'racc_ani_map'
  self.primary_key = :ani_map_id
  
  
  oath_keeper :meta => [[:ani_group,:name]]

  before_validation :set_app_id
  
  validates_presence_of :ani, :app_id
  validates_numericality_of :ani
  
  belongs_to :ani_group
  
  private
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
end
