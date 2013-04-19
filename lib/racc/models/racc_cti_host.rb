class RaccCtiHost < ActiveRecord::Base
  self.table_name = "racc_cti_hosts"
  self.primary_key = :cti_hosts_id

  validates_numericality_of :port, :only_integer => true
  validates_uniqueness_of :cti_name, :scope => :app_id
end
