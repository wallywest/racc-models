class DestinationValidationFormat < ActiveRecord::Base
  self.table_name = :web_destination_validation_formats
  
  validates_presence_of :name, :regex, :error_message, :description
  validates_uniqueness_of :name
  validates_format_of :name, :with => /\A[[:upper:][:lower:]\d_]{1,64}\Z/, :message => "must only contain letters, numbers, and underscores.  It also cannot exceed 64 characters."

  # NOTE: This model is audited, but audits aren't displayed in the gui b/c there is no app_id.
  
  oath_keeper

  HUMANIZED_ATTRIBUTES = {:regex => "Regular expression"}
  
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def nbr_destination_properties
    DestinationProperty.all(:conditions => ["validation_format = ?", self.name]).size
  end
end
