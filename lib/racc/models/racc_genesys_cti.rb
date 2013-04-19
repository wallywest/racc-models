class RaccGenesysCti < ActiveRecord::Base  
  self.table_name = "racc_cti_genesys"
  self.primary_key = :cti_genesys_id
  
  
  oath_keeper
end
