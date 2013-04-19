# Destination Property models contain a set of properties, referred to by name.   
# The percentage of calls to record, the *8 transfer pattern convention that is expected, and other properties are represented.
class DestinationProperty < ActiveRecord::Base
  self.table_name = 'racc_destination_property'
  self.primary_key = :destination_property_id
  
  DIVR_DESTINATION_PROPERTY = 'NETWORK_DIVR'

  
  oath_keeper

  @transfer_pattern_values = %w[A S 1 2 3 B W E Z N -]
  @transfer_method_values = %w[0 1 3 B R D]
  @transfer_type_values = %w[B C F S T]
  @transfer_lookup_values = %w[N A O R D]
  @outdial_format_values = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  @agent_type_values = %w[D S H Q]
  @dest_loc_values = %w[V E]
  @dtypes = %w[M D O R P 5]

  attr_accessor :copy_isup_data, :copy_isup_oli

  class << self
    
    attr_reader :transfer_pattern_values, :transfer_method_values, :transfer_type_values,
                :transfer_lookup_values, :outdial_format_values, :agent_type_values,
                :dest_loc_values, :dtypes
        
  end
    
  has_many  :racc_destinations, 
            :class_name => "Destination", 
            :finder_sql => proc {"select * from racc_destination where app_id='#{app_id}' and destination_property_name='#{destination_property_name}'"}
                          
  belongs_to  :racc_route, 
              :class_name => "RaccRoute", 
              :foreign_key => "route_id"

  scope :mapped, where(:dtype => 'M')
  #scope :hidden, ->(bool) { where(hidden: bool) }
  scope :queues, where(:agent_type => 'Q')
  scope :divrs, where(:destination_property_name => DIVR_DESTINATION_PROPERTY)
  scope :not_mapped, where("racc_destination_property.dtype != 'M'")
  scope :no_queues, where("agent_type != 'Q'")
  default_scope where(hidden: false)

  attr_protected :app_id
  
  validates_presence_of :app_id, 
                        :destination_property_name, 
                        :recording_percentage, 
                        :transfer_method, 
                        :transfer_type, 
                        :outcome_timeout, 
                        :retry_count, 
                        :terminate, 
                        :transfer_lookup, 
                        :max_speed_digits, 
                        :music_on_hold, 
                        :dial_or_block, 
                        :pass_parentcallID, 
                        :cdr_auth,
                        :destination_form,
                        :validation_format
    
  validates_length_of :destination_property_name, 
                      :music_on_hold, 
                      :maximum => 64
  
  validates_length_of :transfer_method, 
                      :transfer_lookup, 
                      :is => 1, 
                      :message => 'must be 1 character'
  
  validates_numericality_of :outcome_timeout, 
                            :recording_percentage
  
  validates_numericality_of :retry_count, 
                            :max_speed_digits, 
                            :cti_routine,
                            :only_integer => true, 
                            :message => 'must be an integer'
  
  validates_numericality_of :outdial_format,
                            :only_integer => true,
                            :greater_than_or_equal_to => 0,
                            :less_than_or_equal_to => 11
  
  validates_format_of :destination_property_name,
                      :with => /\A[A-Za-z\d_\-\+\*\#]+\Z/,
                      :allow_blank => true,
                      :message => "may contain only letters, numbers, and the characters _, -, +, *, and #"
  
  validates_format_of :dial_or_block, 
                      :with => /\A[D|B]\Z/, 
                      :message => 'must be set to either D (Dial) or B (Block)'
  
  validates_format_of :pass_parentcallID, 
                      :with => /\A[T|F]\Z/, 
                      :message => 'must be True or False'
  
  validates_format_of :cdr_auth, 
                      :with => /\A[T|F]\Z/, 
                      :message => 'must be True or False'
    
  # "A" for AT&T, "S" for Sprint, "1" for Vail internal type 1, and blank if transfers are allowed from the destination
  validates_format_of :transfer_pattern, 
                      :with => /\A[#{self.transfer_pattern_values.join('|')}]\Z/, 
                      :message => "allows only the following values: #{self.transfer_pattern_values.join(', ')}"
   
  # "3" for 302-Moved, "B" for Bridge, "R" for refer
  validates_format_of :transfer_method, 
                      :with => /\A[#{self.transfer_method_values.join('|')}]\Z/, 
                      :message => "allows only the following values: #{self.transfer_method_values.join(', ')}"
     
  # For AT&T only..."B" for blind, "C" for consult, "F" for conference
  validates_format_of :transfer_type, 
                      :with => /\A[#{self.transfer_type_values.join('|')}]\Z/, 
                      :message => "allows only the following values: #{self.transfer_type_values.join(', ')}"
  
  # Type of processing to perform on a transfer number from this destination
  validates_format_of :transfer_lookup, 
                      :with => /\A[#{self.transfer_lookup_values.join('|')}]\Z/, 
                      :message => "allows only the following values: #{self.transfer_lookup_values.join(', ')}"
                      
  validates_format_of :agent_type, :with => /\A[#{self.agent_type_values.join('|')}]\Z/,
                      :message => "allows only the following values: #{self.agent_type_values.join(', ')}"
                      
  validates_inclusion_of :dest_loc, :in => DestinationProperty.dest_loc_values, 
                         :message => "allows only the following values: #{self.dest_loc_values.join(', ')}"

  validates_inclusion_of :commands_ok, :in => ['T', 'F'], 
                         :message => "must be True or False"
                         
  validates_inclusion_of :dtmf_to_o, :in => ['T', 'F'], 
                         :message => "must be True or False"

  validates_inclusion_of :dtmf_from_o, :in => ['T', 'F'], 
                         :message => "must be True or False"

  validates_numericality_of :isup_enabled, :greater_than_or_equal_to => 0, :less_than => 2 ** (11 * 8), :only_integer => true
                         
  validates_format_of :target_ack, :with => /\A[\d\*#A-D]+\Z/, :allow_blank => true                       
  
  validates_numericality_of :destination_attribute_bits, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 2147483647, :only_integer => true

  validates_numericality_of :ani_override, :allow_blank => true, :only_integer => true, :greater_than_or_equal_to => 0
  validates_length_of :ani_override, :maximum => 14
  validate :hideability, if: -> { self.hidden }
  
  before_validation :set_app_id, :compute_isup_enabled
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end

  def self.all_names(app_id)
    DestinationProperty.where(:app_id => app_id).select(:destination_property_name).map(&:destination_property_name) << ""
  end

  def allows_mapping?
    dtype == 'M'
  end

  private
  
  def compute_isup_enabled
    if self.copy_isup_data || self.copy_isup_oli
      self.isup_enabled = self.copy_isup_data.to_i | self.copy_isup_oli.to_i
    end
  end

  def hideability
    if Destination.where(app_id: self.app_id, destination_property_name: self.destination_property_name).any?
      errors.add(:base, "Destination property cannot be hidden when in use by Destinations")
    end
  end
  
end
