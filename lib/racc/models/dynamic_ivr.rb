class DynamicIvr < ActiveRecord::Base  
  self.table_name = :web_dynamic_ivrs

  
  oath_keeper
  
  has_many :dynamic_ivr_destinations, :dependent => :destroy
  has_many :destinations, :through => :dynamic_ivr_destinations
  
  STATE_NEW = "In Progress"
  STATE_VALID = "Valid"
  STATE_INVALID = "Invalid"
  STATE_ENABLED = "Enabled"
  STATE_ACTIVE = "Active"
  
  scope :available, where(:state => [STATE_ENABLED, STATE_ACTIVE])
  scope :available_for, lambda { |app_id| available.where(:app_id => app_id) }

  def save_state(new_state)
    self.state = new_state
    ivr_string = JSON.parse(self.json_string)
    ivr_string["metadata"]["tree_state"] = new_state
    self.json_string = ivr_string.to_json
    self.save    
  end
  
  def is_available?
    [STATE_ENABLED, STATE_ACTIVE].include?(self.state)
  end
  
  def self.find_all_in_divrs(_app_id, _type)
    all_data = []
    all_jsons = DynamicIvr.select(:json_string).where(:app_id => _app_id).map{ |divr| divr.json_string }
    
    all_jsons.each do |j|
      case _type
      when "prompts"
        all_data << j.scan(/\"prompt_id\":\"[\d]+\"|\"default_error_msg_[\d]+\":\"[\d]+\"|\"default_goodbye_msg\":\"[\d]+\"/).map{ |a| a.gsub(/prompt_id|\"|\:|default_error_msg_[\d]+|default_goodbye_msg/,'') }
      when "transfer_strings"
        all_data << j.scan(/\"number\":\"[\w\d\s\@\:\/\.\[\]]+\"/).map{ |a| a.gsub(/\"number\":|\"/,'') }        
      end
    end
    
    all_data.flatten
  end
  
  def copy_ivr(_name)
    begin
      ActiveRecord::Base.transaction do 
        new_divr = self.dup
    
        new_divr.name = _name
        new_divr.state = copied_divr_state(self.state)
        
        if new_divr.save
          new_json = JSON.parse(self.json_string)   
          new_json["data"] = _name
          new_json["metadata"]["tree_state"] = copied_divr_state(self.state)
          new_json["attr"]["id"] = new_divr.id
    
          new_divr.json_string = new_json.to_json
          new_divr.save
        end
      end
    rescue => e
      Rails.logger.error "An error occurred while copying divr id #{self.id}.  Error is: #{e.to_s}"
    end
  end
  
  private
  
  def copied_divr_state(original_state)
    if [STATE_ACTIVE, STATE_ENABLED].include?(original_state)
      return STATE_VALID
    else
      return original_state
    end
  end
end
