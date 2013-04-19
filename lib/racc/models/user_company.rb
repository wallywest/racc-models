class UserCompany < ActiveRecord::Base
  self.table_name = 'web_users_companies_xref'
  
  belongs_to :user
  belongs_to :company, :foreign_key => :app_id
  
  
  oath_keeper
end
