class CompanySettingXref < ActiveRecord::Base
  belongs_to :company
  belongs_to :setting
  
  after_save :update_time
  
  def update_time
    company = self.company
    company.company_config.modified_time_unix = Time.now.to_i
    company.save
  end
  
end
