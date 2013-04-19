class RecordedDnis < ActiveRecord::Base
  RecordedDnis.inheritance_column = nil
  
  belongs_to :company, :foreign_key => "app_id"
  
  self.table_name = "racc_cust_parms"
  self.primary_key = :cust_parms_id
  
  
  oath_keeper
  
  attr_accessible :s1, :s2, :i1, :i2, :i3, :i4
  
  validates_presence_of :app_id

  validate :validate_record

  before_validation :set_i_fields
  before_save :update_modified_time
  before_save     :set_i4
  after_save      :update_wildcard_dnis_setting
  after_create :update_vlabels_on_create, :if => :recording_by_rules_on
  after_destroy :update_vlabels_on_destroy, :if => :recording_by_rules_on
  after_destroy   :update_wildcard_dnis_setting
  

  # Set the value that Shumna needs in the platform
  def set_i4
    case i5
      when 1
        self.i4 = 1
      when 2
        self.i4 = 2
      when 3
        self.i4 = 3
      when 4
        self.i4 = 3
      when 5
        self.i4 = 3
      when 6
        self.i4 = 4
      when 7
        self.i4 = 5
      when 8
        self.i4 = 3
      else
        self.i4 = 0
    end    
  end
  
  def set_i_fields
    # 'R' is the type that distinguishes recording rules for racc_cust_parms table
    self.type = 'R'
    self.i1 = self.i1.to_i
    self.i2 = default_int(self.i2)
    self.i3 = default_int(self.i3)
    self.i5 = default_int(self.i5)
    self.i6 = default_int(self.i6)
  end
  
  def default_int(int_to_default)
    if int_to_default.blank?
      int_to_default = -1
    else
      int_to_default = int_to_default.to_i
    end
    int_to_default
  end

  def validate_record
    inbound_dnis = self.parm_key.to_s
    name = self.parm_name
    call_type = self.s1
    destination = self.s2
    destination_type_gui_value = self.i5
    retention_days = self.i6
  
    if app_id
    
      # If the name is blank throw an error
      # otherwise make sure the parm name field only has A-Za-z0-9_-* characters
      unless name =~ /^[\w-]{0,40}$/
        self.errors[:base] << ("Name must have letters, numbers, underscores or dashes only")   
      end
    
    
      unless inbound_dnis =~ /^[\*]$|^[0-9]{3,10}$/
        self.errors[:base] << ("Inbound DNIS must have 3 - 10 digits")   
      end
    
      # Validate s1 (Call type) only allows characters letters, digits, underscores, periods, asterisks and dashes 
      unless call_type  =~ /^[\*]$|^[\w\.-]{1,60}$/ 
        self.errors[:base] << ("Call type must have at most 60 letters, numbers, underscores, periods and dashes")
      end

      self.errors[:base] << ("Days to Save Recordings must have a value between 1 and 730 or use the checkbox for the default value")  unless retention_days > -2 and retention_days < 731 

      self.errors[:base] << ("Days to Save Recordings must not be zero.  Use checkbox for default value or enter between 1 and 730") if retention_days == 0

      destination_type = DestinationType.find_by_app_id_and_gui_value(app_id, destination_type_gui_value)

      case destination_type_gui_value
        when 1
          unless destination =~ /^[\*]$|^[0-9]{10}$/
            self.errors[:base] << (destination_type.error_messages)
          end          
        when 2
          unless destination =~ /^[\*]$|^[0-9]{2,9}$/
            self.errors[:base] << (destination_type.error_messages)
          end
        when 3
          unless destination =~ /[\*]|[0-9]{10}\+[0-9]{2,9}/
            self.errors[:base] << (destination_type.error_messages)
          end
        when 4
          unless destination =~ /^[\*]$|^[0-9]{10}$/
            self.errors[:base] << (destination_type.error_messages)
          end
        when 5
          unless destination =~ /^[\*]$|^sip:\w*@\w*\.[A-Za-z]{3}$/
            self.errors[:base] << (destination_type.error_messages)
          end
        when 6
          unless destination =~ /^[\*]$|^[A-Za-z0-9\.]{1,20}$/
            self.errors[:base] << (destination_type.error_messages)
          end
        when 7
          unless destination =~ /^[\*]$|^[A-Za-z0-9\.]{1,30}$/
            self.errors[:base] << (destination_type.error_messages)
          end
        when 8
          unless destination =~ /^[\*]$|^[0-9\+]{1,30}$/
            self.errors[:base] << (destination_type.error_messages)
          end
      end
    
      # Validates a call center (s2) only allows up to 20 digits or a plus or a single asterisk character. 
  
      if self.new_record? && RecordedDnis.find_by_app_id_and_parm_name_and_parm_key_and_type(self.app_id, self.parm_name, self.parm_key, self.type)
        self.errors[:base] << ('That name is already in use for this Inbound DNIS.')
      elsif !self.new_record? && RecordedDnis.where('app_id = ? AND parm_name = ? AND parm_key = ? AND type = ?', self.app_id, self.parm_name, self.parm_key, self.type).length > 1
        self.errors[:base] << ('That name is already in use for this Inbound DNIS.')      
      end
  
      if !self.i1.is_a?(Integer) || (self.i1 < 0) || (self.i1 > 100)
        self.errors[:base] << ('% of recordings to keep must be an integer between 0 and 100')
      end
  
      if !self.i2.is_a?(Integer) || self.i2 > 999 || self.i2 < -1
        self.errors[:base] << ('Smallest no. of transfers must be an integer greater than 0 (or -1 for \"not used\") and less than 1000')
      end
  
      if !self.i3.is_a?(Integer) || (self.i3 < 1 && self.i3 != -1)
        self.errors[:base] << ('Lowest survey score to trigger recording must be an integer greater than 0 (or -1 for \"not used\")')
      end
    end # end if app_id
  end
  
  def update_modified_time
    self.modified_time = Time.zone.now
  end
  
  def update_wildcard_dnis_setting
    company_config = CompanyConfig.find(self.app_id)
  
    if RecordedDnis.wildcards?(self.app_id)
      company_config.wildcard_dnis = 'T'
    else
      company_config.wildcard_dnis = 'F'
    end
    
    company_config.save
  end
  
  def self.wildcards?(app_id)
    RecordedDnis.select("parm_key").where(:app_id => app_id, :type => 'R', :parm_key => '*').size > 0
  end
  
  def self.has_rule_for_vlabel?(app_id, vlabel)
    RecordedDnis.select("parm_key").where(["app_id = ? AND type = ? AND parm_key IN (?)", app_id, 'R', ['*', vlabel]]).size > 0
  end
  
  private
  
  def recording_by_rules_on
    Company.find(self.app_id).recording_type == 'R'
  end
  
  def update_vlabels_on_create
    #we don't care about auditing this
    if self.parm_key == '*'
      VlabelMap.update_all(["full_call_recording_enabled = ?, full_call_recording_percentage = ?", "M", 100], ["app_id = ?", self.app_id])
    else
      VlabelMap.update_all(["full_call_recording_enabled = ?, full_call_recording_percentage = ?", "M", 100], ["app_id = ? AND vlabel = ?", self.app_id, self.parm_key])
    end
  end
  
  def update_vlabels_on_destroy
    if !RecordedDnis.wildcards?(self.app_id)
      company = Company.find(self.app_id)
      company.update_vlabels_based_on_rec_rules
    end
  end
end
