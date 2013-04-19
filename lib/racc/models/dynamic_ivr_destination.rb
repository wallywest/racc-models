class DynamicIvrDestination < ActiveRecord::Base
  self.table_name = :web_dynamic_ivrs_destinations
  
  oath_keeper
  
  belongs_to :dynamic_ivr
  belongs_to :destination
  
  before_save :state_to_active
  after_save :update_prev_divr_state
  after_destroy :state_to_inactive
  
  
  private
  
  def state_to_active
    ivr = DynamicIvr.find(self.dynamic_ivr_id)
    ivr.save_state(DynamicIvr::STATE_ACTIVE)
  end
  
  def update_prev_divr_state
    divr_changes = self.changed? ? self.changes["dynamic_ivr_id"] : nil

    if divr_changes && old_divr_id = divr_changes[0]
      set_state_to_enabled(old_divr_id)
    end
  end
  
  def state_to_inactive
    set_state_to_enabled(self.dynamic_ivr_id)
  end
  
  def set_state_to_enabled(divr_id)
    if DynamicIvrDestination.where(:dynamic_ivr_id => divr_id).size == 0
      ivr = DynamicIvr.find(divr_id)
      ivr.save_state(DynamicIvr::STATE_ENABLED)
    end
  end
end
