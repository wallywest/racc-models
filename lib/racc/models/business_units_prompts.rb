class BusinessUnitsPrompts < ActiveRecord::Base
  belongs_to :business_unit
  self.table_name = :web_business_units_prompts
  
  validates_numericality_of :recording_app_id
  validates_numericality_of :recording_job_id
end
