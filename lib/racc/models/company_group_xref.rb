class CompanyGroupXref < ActiveRecord::Base
  belongs_to :company
  belongs_to :group
end
