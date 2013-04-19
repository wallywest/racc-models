class PromptSet < ActiveRecord::Base
  belongs_to :business_unit, :foreign_key => "business_unit_id"
  has_many :slots, :order => "prompt_order ASC", :dependent => :destroy
  self.table_name = :web_prompt_sets
  
  validates_uniqueness_of :name, :scope => :business_unit_id
  validates_format_of :name, :with => /\A[[:upper:][:lower:]\d_]+\Z/, :message => "may only have letters, numbers, and underscores."
  validates_presence_of :app_id

  accepts_nested_attributes_for :slots, :allow_destroy => true
  
  
  oath_keeper
  
  before_validation :set_app_id
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
  
end
