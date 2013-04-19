class GroupDefaultRoute < ActiveRecord::Base
  self.table_name = :web_group_default_routes
  
  belongs_to :group
  belongs_to :vlabel_map
end
