class CtiRoutine < ActiveRecord::Base
  self.table_name = :web_cti_routines
  
  has_many :group_cti_routine_xrefs, :dependent => :destroy
  
  validates_presence_of :value, :description, :target
  validates_numericality_of :value, :only_integer => true
  validates_length_of :description, :maximum => 255
  validates_inclusion_of :target, :in => %w(op destination)

  # Note: Non-numeric values are excluded from the unique callback b/c if a non-numeric value
  # is entered, it is considered zero b/c the value field is an integer.  See Redmine #3863
  validates_uniqueness_of :value, :scope => [:app_id, :target], :allow_nil => true, :allow_blank => true, :unless => Proc.new {|cr| cr.value_is_char }

  attr_accessor :value_is_char

  
  oath_keeper
end
