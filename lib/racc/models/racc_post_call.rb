class RaccPostCall < ActiveRecord::Base   
  self.table_name = "racc_post_call"
  self.primary_key = :post_call_id
  
  
  oath_keeper
end
