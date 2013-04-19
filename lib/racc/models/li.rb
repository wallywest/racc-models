class Li < ActiveRecord::Base
  self.table_name = :racc_dli_li
  belongs_to :dli

  HUMANIZED_ATTRIBUTES = {:dpct => "Distribution %"}
  
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end  
  
  
  oath_keeper :meta => [[:dli, :value]]

  before_validation :set_app_id
  
  validates_presence_of :app_id, :value, :dpct, :modified_by, :description
  validates_numericality_of :dpct, :greater_than => 0, :less_than_or_equal_to => 100
  
  before_create :default_modified_time
  
  private

  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
  
  def default_modified_time
    self.modified_time = Time.now
  end
end
