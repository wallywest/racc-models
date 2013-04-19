class BusinessUnit < ActiveRecord::Base
  has_many :prompt_sets, :foreign_key => "business_unit_id", :dependent => :destroy
  has_and_belongs_to_many :users, :join_table => :web_business_units_users
  has_many :prompt_accesses, :class_name => "BusinessUnitsPrompts"
  self.table_name = :web_business_units
  
  validates_presence_of :name
  validates_format_of :name, :with => /\A[[:upper:][:lower:]\d_]+\Z/, :message => "The name may only have letters, numbers, and underscores."
  validates_uniqueness_of :name, :scope => :app_id
  
  validates_presence_of :app_id
  validates_numericality_of :app_id

  accepts_nested_attributes_for :prompt_sets, :allow_destroy => true
  accepts_nested_attributes_for :prompt_accesses, :allow_destroy => true
  
  
  oath_keeper
  
  before_validation :set_app_id
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
  
  def available_prompts
    prompts = []
    self.prompt_accesses.each do |access|
      prompts += Prompt.joins("INNER JOIN recordings ON recordings.recording_id = prompts.recording_id").where('app_id = :app_id AND job_id = :job_id', {:app_id => access.recording_app_id, :job_id => access.recording_job_id})
    end
    return prompts.uniq
  end
  
  def recordings
    recordings = []
    self.prompt_accesses.each do |access|
      recordings += VailRecording.joins("LEFT JOIN  prompts ON prompts.recording_id = recordings.recording_id").where('app_id = :app_id AND job_id = :job_id AND UPPER(keyword) = :keyword', {:app_id => access.recording_app_id, :job_id => access.recording_job_id, :keyword => "PROMPTS"}).includes(:prompt)
    end
    return recordings.uniq
  end
end
