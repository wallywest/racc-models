# Find array of arrays of consecutive groups of indices.
# used in #check_time_segment_set_coverage_full_day
module ArrayGroups
  def groups
    @grps = []
    self.each do |i|
      if @grps[-1] && @grps[-1][-1] && @grps[-1][-1] + 1 == i
        @grps[-1] << i
      else
        @grps << [i]
      end
    end
    @grps
  end
end

class Profile < ActiveRecord::Base
  self.table_name = "web_profiles"
  belongs_to :package, :inverse_of => :profiles
  has_many :time_segments, :inverse_of => :profile, :dependent => :destroy, :order => "start_min ASC"
  
  validates_presence_of :name, :app_id
  validates_length_of :name, :maximum => 255
  validate :one_day_checked
  
  after_destroy :update_errors
  
  
  oath_keeper :master_event => {:type => Package, :finder => Proc.new {|t| t.package }}
  
  accepts_nested_attributes_for :time_segments, :allow_destroy => true

  def self.auditable_search_field; :name; end
  
  public
  
  attr_accessor :orig_start
  attr_accessor :orig_end
  
  def one_day_checked
    unless sun or mon or tue or wed or thu or fri or sat
      errors.add(:base, 'At least one day should be selected')
    end
  end
  
  # Deletes all errors related to the profile set and validates the
  # profile set by checking the coverage for gaps and duplicated days.
  def validate_profile_set
    if (not exception_date?) and package
      self.package.delete_profile_set_errors
      self.package.check_day_coverage
    end
  end
  
  # Returns true if the profile has a time segement related to it
  # otherwise returns false
  def has_time_segments
    ts = false
    if not self.time_segments.empty?
      ts = true
    end
    ts
  end
  
  def build_ts_pair(start1, start2_pretty, end2)
    start2 = TimeSegment.time_to_minutes(start2_pretty)
    
    t = TimeSegment.new
    t.start_min = start1
    t.end_min = start2 - 1
    self.time_segments << t
        
    t = TimeSegment.new 
    t.start_min = start2
    t.end_min = end2
    self.time_segments << t
  end
  
  # First deletes errors related to the time segments
  # Second will create any profile set errors
  def update_errors
    delete_time_segment_set_errors
    validate_profile_set
  end
  
  # Delete all errors that are related to the time segment set
  def delete_time_segment_set_errors
    RaccError.delete_all(["package_id = ? and profile_id = ? and time_segment_id = -1", self.package_id, self.id])
  end
  
  #For an instance of a Profile this will convert the boolean days of week into
  #the base 10 number that will represent the binary bit mask
  #i.e. sun => true, tues => true, sat => true results in a base 10 value of 162
  def create_day_of_week_base10_value
    dow = 0
    
    if self.sun
      dow += 128
    end
    
    if self.mon
      dow += 64
    end
    
    if self.tue
      dow += 32
    end
    
    if self.wed
      dow += 16
    end
    if self.thu
      dow += 8
    end
    if self.fri
      dow += 4
    end
    if self.sat
      dow += 2
    end
    
    dow
  end
  
  # Returns FALSE if the exception date is nil
  # otherwise returns true
  def exception_date?
    if self.day_of_year.nil?
      false
    else
      true
    end
  end
  
  # Returns an array of the profile week with each slot true or false
  # Sun =>0, Mon => 1, ... , Sat =>6
  @@days_order = [:sun, :mon, :tue, :wed, :thu, :fri, :sat]
  def all_days_ordered_sun_thru_sat
    a = Array.new
    a[0] = self.sun
    a[1] = self.mon
    a[2] = self.tue
    a[3] = self.wed
    a[4] = self.thu
    a[5] = self.fri
    a[6] = self.sat
    a
  end
  
  def active_days
    h = all_days
    h.delete_if {|key, value| value == false || value == nil}
  end
  
  def sun_num
    day_num(self.sun)
  end
  
  def day_num(day)
    num =0
    if day
      num = 1
    end
    num
  end

  def all_days
    h = Hash.new
    h["sun"] = self.sun
    h["mon"] = self.mon
    h["tue"] = self.tue
    h["wed"] = self.wed
    h["thu"] = self.thu
    h["fri"] = self.fri
    h["sat"] = self.sat
    h
  end
  
  def create_time_segment_error(err)
    t_error = RaccError.new
    t_error.error_message=err
    t_error.profile_id=self.id
    self.package.racc_errors << t_error
  end
  
  # Verifies that the time segment set for the current profile
  # covers every minute of a day (0-1439) with no gaps or overlaps
  def check_time_segment_set_coverage_full_day(start_time, num_checked)
    # use Set class to perform intelligent merge/intersection calculations on range 0..1439
    all_day = (0..1439).to_a

    # check only non-destroyed time segments
    non_destroyed_time_segments = time_segments.select {|ts| not ts.marked_for_destruction?}.compact

    coverage = []
    non_destroyed_time_segments.each do |ts|
      this_time = (ts.start_min .. ts.end_min).to_a
      # Array#uniq! return array of unique elements or nil if no changes (all unique)
      if (coverage + this_time).uniq!
        create_time_segment_error("Time Segment Set invalid because there are overlapping time segments starting at #{ts.pretty_start} in profile #{self.name}")
      end
      # Array#| Set Union on two arrays
      coverage |= this_time
    end

    unless (all_day - coverage).empty?
      uncovered_ranges = all_day - coverage
      uncovered_ranges.extend ArrayGroups

      uncovered_ranges.groups.each do |u|
        def pretty(i); TimeSegment.minutes_to_pretty(i); end
        create_time_segment_error("Time Segment Set invalid because there is a gap at #{pretty(u[0])} for profile #{self.name}")

      end
    end

  end
  
  #return true if the all time segments related to the profile are unique
  #return false otherwise
  def has_unique_ends
    self.time_segments.collect { |c| c.end_min }.uniq.size == self.time_segments.size
  end
  
  #return true if all begin times in the related time segment set are true
  #otherwise return false
  def has_unique_starts
    self.time_segments.collect { |c| c.start_min }.uniq.size == self.time_segments.size
  end
  
  def time_segment_attributes=(ts_attributes) 
    ts_attributes.each do |attributes|
      if !attributes[:pretty_start].blank? and !attributes[:pretty_end].blank?
        time_segments.create(attributes.merge(:app_id => app_id))
      end
    end 
  end
  
  #Returns a new profile object with a copy of self
  def copy
    obj = self.dup
    obj.attributes = {:created_at => nil, :updated_at => nil}
    obj
  end
  
  def out_of_range_segments
    self.time_segments.select {|ts| ts.out_of_range?}
  end
  
  def last_day
    6.downto(0) do |i|
      return @@days_order[i] if self.all_days_ordered_sun_thru_sat[i] 
    end
    
  end
end
