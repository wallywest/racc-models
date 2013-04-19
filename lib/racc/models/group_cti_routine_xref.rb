class GroupCtiRoutineXref < ActiveRecord::Base
  self.table_name = :web_groups_cti_routines_xref
  
  belongs_to :group
  belongs_to :cti_routine
  
  validates_uniqueness_of :cti_routine_id, :scope => :group_id
end
