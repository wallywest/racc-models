class CompanyConfig < ActiveRecord::Base
  self.primary_key = :app_id
  self.table_name = :racc_companies
  
  @racc_boolean = /(T|F)/i
  
  belongs_to :company, :foreign_key => :app_id

  validates_numericality_of :default_dsat_score
  validates_numericality_of :save_no_xfers_pct, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100, :allow_nil => true
  validates_format_of :calltype_survey_enabled, :with => @racc_boolean
  validates_format_of :survey_to_agent, :with => @racc_boolean
  validates_format_of :recording_enabled, :with => @racc_boolean
  validates_format_of :defer_discard, :with => @racc_boolean
  validate :valid_default_survey
  validates_length_of :tdd_phone, :tdd_fail_msg, :dce_prompt, :maximum => 64
  validates_length_of :cn_mask, :maximum => 255
  validates_format_of :alternate_command_character, :with => /\A\s*([ABCDG\s]{1})\s*\Z/, :allow_blank => true, :message => "must be A|B|C|D|G or blank"
  
  before_validation :update_defer_discard
  before_save :update_modified_time_unix
  after_save :update_operations
  
  HUMANIZED_ATTRIBUTES = {
    :save_no_xfers_pct => "Single Transfer Recording Percentage"}
  
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  
  oath_keeper
  
  private 
  
  def valid_default_survey

    case self.default_survey
    when String
      unless self.default_survey.blank? || VlabelMap.exists?(:app_id => self.app_id, :vlabel => self.default_survey) || TransferMap.exists?(:app_id => self.app_id, :transfer_string => self.default_survey)
        errors.add(:default_survey, "does not exist")
      end
    else
      errors.add(:default_survey, "is invalid")
    end

  end

  def update_operations
    if self.changed.include?('calltype_survey_enabled') && self.calltype_survey_enabled == 'T'
      Operation.update_all(["post_call = ?", 'F'], ["app_id = ?", self.app_id])
    end
  end

  def update_modified_time_unix
    self.modified_time_unix = Time.now.to_i
  end
  
  def update_defer_discard
    self.defer_discard = 'F' if self.recording_enabled == 'F'
  end
end
