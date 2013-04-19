class Slot < ActiveRecord::Base
  belongs_to :prompt_set
  belongs_to :prompt
  self.table_name = :web_slots

  validates_presence_of :app_id

  
  oath_keeper
  
  before_validation :set_app_id
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
end
