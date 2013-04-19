class SurveyGroup < ActiveRecord::Base
  self.table_name = :racc_survey_groups
  self.primary_key = :survey_group_id
  
  has_many :vlabel_maps
  
  
  oath_keeper
  
  HUMANIZED_ATTRIBUTES = {:survey_vlabel => "Survey Route Label", :percent_to_survey => "Survey Rate %", :dsat_score => "Dissatisfied Score"}
  
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  attr_protected :app_id
  
  validates_presence_of :app_id, :name, :survey_vlabel, :percent_to_survey, :dsat_score, :announcement_file, :modified_by
  validates_numericality_of :percent_to_survey, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100
  validates_numericality_of :dsat_score, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100
  validates_uniqueness_of :survey_vlabel, :scope => :app_id
  validate :transfer_string_exists

  before_validation :set_app_id

  scope :for, lambda {|app_id| where(:app_id => app_id)}
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
  
  def transfer_string_exists
    unless self.class.lookup_transfer_string(self.survey_vlabel, self.app_id)
      errors.add(:survey_vlabel, "must be a valid speed dial or route.")
    end
  end
  
  def self.lookup_transfer_string(survey_vlabel, app_id)
    TransferMap.first(:conditions => {:app_id => app_id, :transfer_string => survey_vlabel}) || VlabelMap.first(:conditions => {:app_id => app_id, :vlabel => survey_vlabel})
  end
end
