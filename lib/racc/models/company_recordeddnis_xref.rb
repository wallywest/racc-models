class CompanyRecordeddnisXref < ActiveRecord::Base
  belongs_to :company
  belongs_to :recorded_dnis
end
