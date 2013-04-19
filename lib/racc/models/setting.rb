class Setting < ActiveRecord::Base
  self.table_name = "racc_nvp"
  self.primary_key = :nvp_id
  
  
  oath_keeper
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :app_id
  validates_format_of :name, :with => /\A[[:upper:][:lower:]\d_]+\Z/, :message => "may only have letters, numbers, and underscores."

  belongs_to :company, :foreign_key => "app_id"
  
  before_save :update_modified_time
  after_save :update_racc_companies_modified_time
  after_destroy :update_racc_companies_modified_time

  private 
  
  def update_racc_companies_modified_time
    self.company.company_config.modified_time_unix = Time.now
    self.company.save
  end
  
  def update_modified_time
    self.modified_time = Time.zone.now
  end
end
