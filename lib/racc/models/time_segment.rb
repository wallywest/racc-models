class TimeSegment < ActiveRecord::Base
  self.table_name = "web_time_segments"
  belongs_to :profile, :inverse_of => :time_segments
  has_many :routings, :inverse_of => :time_segment, :dependent => :destroy
  
  after_destroy :delete_routing_set_errors, :validate_time_segment_set
  
  validates_presence_of :start_min, :end_min, :app_id
  validates_inclusion_of :start_min, :in => 0..1438, :message => "Should be between 0 and 1438"
  validates_inclusion_of :end_min, :in => 1..1439, :message => "Should be between 1 and 1439"
  validates_confirmation_of :start_min,
                            :message => "Should have a start before end",
                            :if => Proc.new { |u| u.validates_start_before_end }
  validate :max_routing_exits
  
  
  oath_keeper :master_event => {:type => Package, :finder=> Proc.new {|t| t.profile.package}}
  
  accepts_nested_attributes_for :routings, :allow_destroy => true
  
  def delete_routing_set_errors
    RaccError.delete_all(["package_id = ? and profile_id = ? and time_segment_id = ?", self.profile.package_id, self.profile_id, self.id])
  end
  
  def validate_time_segment_set
    return unless profile
    self.profile.delete_time_segment_set_errors
    self.profile.check_time_segment_set_coverage_full_day(0,0)
  end
  
  def has_routings
    r = true
    if self.routings.empty?
      self.profile.create_time_segment_error("The time segment #{self.start_min} to #{self.end_min} for profile #{self.profile.name} has no routings created.")
      r = false
    end
    r
  end
  
  def validate_unique_destids
    if self.routings.length != self.routings.collect {|r| r.call_center}.uniq.length
      create_routing_set_err("There are duplicate destid's in the routings")
    end
  end
  
  def validates_start_before_end
    valid = true
    if self.start_min.nil? or self.start_min == ""
      errors.add(:end_time, "Start or end not in a valid numeric format")
      valid = false
    end
    
    if self.end_min.nil? or self.end_min == ""
      errors.add(:end_time, "Start or end not in a valid numeric format")
      valid = false
    end
    
    if valid
      if self.start_min >= self.end_min
        errors.add(:end_time, "Start can not be before or at end")
        valid = false
      end
    end
    
    valid
  end
  
  def validate_unique_destination_order_pairs
    has_uniq_pairs = true
    uniq_dests = self.routings.collect {|d| d.destination}.uniq
    
    uniq_dests.each do |dest|
      destRows = self.routings.select {|r| dest == r.destination}
      
      if destRows.collect{|row| row.order}.uniq.length != destRows.length
        has_uniq_pairs = false
        create_routing_set_err("The destination #{dest} in time segment #{self.start_min} to #{self.end_min} in profile #{self.profile.name} has matching call orders")
      end
    end
    has_uniq_pairs
  end
  
  #
  # START select form choices
  #
  # Just a place to store the hours and minures choices for the select forms. Probably could be more elegant. For now, it is here.
  # Example usage in views:
  # <%= f.select :start_hour, @new_time_segment.hours %> : <%= f.select :start_minute, @new_time_segment.minutes %>
  def hours
    Routing.comma_delimited_list(Array("00".."23"))
  end
  
  def minutes
    Routing.comma_delimited_list(Array("00".."59"))
  end
  #
  # END select form choices
  #
  
  # START virtual attributes for time segment select forms
  def start_hour
    unless self.start_min.nil?
      if (self.start_min / 60) > 9
        (self.start_min / 60)
      else
        "0" + (self.start_min / 60).to_s
      end
    end
  end
  
  def start_hour=(hour)
    unless self.start_min.nil?
      self.start_min += (hour.to_i * 60)
    else
      self.start_min = (hour.to_i * 60)
    end
  end
  
  def start_minute
    unless self.start_min.nil?
      if (self.start_min % 60) == 0
        "00"
      else
        (self.start_min % 60)
      end
    end
  end
  
  def start_minute=(minute)
    unless self.start_min.nil?
      self.start_min += (minute.to_i)
    else
      self.start_min = (minute.to_i)
    end
  end
  
  def end_hour
    unless self.end_min.nil?
      if (self.end_min / 60) > 9
        (self.end_min / 60)
      else
        "0" + (self.end_min / 60).to_s
      end
    end
  end
  
  def end_hour=(hour)
    unless self.end_min.nil?
      self.end_min += (hour.to_i * 60)
    else
      self.end_min = (hour.to_i * 60)
    end
  end
  
  def end_minute
    unless self.end_min.nil?
      if (self.end_min % 60) == 0
        "00"
      else
        (self.end_min % 60)
      end
    end
  end
  
  def end_minute=(minute)
    unless self.end_min.nil?
      self.end_min += (minute.to_i)
    else
      self.end_min = (minute.to_i)
    end
  end
  # END virtual attributes for time segment select forms
  
  def pretty_start=(start)
    self.start_min = TimeSegment.time_to_minutes(start)
  end
  
  def pretty_start
    TimeSegment.minutes_to_pretty(self.start_min)
  end
  
  def pretty_end
    TimeSegment.minutes_to_pretty(self.end_min)
  end
  
  def pretty_end=(time_end)
    self.end_min = TimeSegment.time_to_minutes(time_end)
  end
  
  def bar_length
    @minutes = self.end_min.to_i - self.start_min.to_i 
    # if self.id.to_i % 2 == 0
    #    @length =  ((@minutes.to_f/1440.to_f) * 100).ceil
    # else   
       @length =  ((@minutes.to_f/1440.to_f) * 100).floor 
    # end
    
    @length.to_i
  end
  
  def margin_left
    ((self.start_min.to_f/1440.to_f) * 100).to_i
  end
  
  def new_routing_attributes=(routing_attributes)
    routing_attributes.each do |attributes|
      routings.build(attributes.merge(:app_id => self.app_id)).save
    end
  end
  
  
  def destinations(destinations)
    i=0
    destinations.each do |dest|
      rd = RoutingExit.new
      rd.destination_id = dest.destination_id
      rd.call_priority = 1
      self.routings[i].routing_exits << rd
      i += 1
    end
  end

  def check_routing_set_percent_is_100
    routing_total = routing_percentage_total
    
    if routing_total < 100
      msg = "The routing set for profile #{self.profile.name} and time segment #{self.start_min} to #{self.end_min} is less than 100%"
      create_routing_set_err(msg)
    elsif routing_total > 100
      msg = "The routing set for profile #{self.profile.name} and time segment #{self.start_min} to #{self.end_min} is greater than 100%"
      create_routing_set_err(msg)
    end
  end
  
  def create_routing_set_err(msg)
    re = RaccError.new
    re.error_message = msg
    re.profile_id = self.profile.id
    re.time_segment_id = self.id
    self.profile.package.racc_errors << re
  end
  
  def routing_percentage_total
    total = 0
    
    # check only routings not marked for destruction
    non_destroyed_routings = self.routings.select {|r| not r.marked_for_destruction?}.compact
    
    for route in non_destroyed_routings
      total += route.percentage
    end
    total
  end
  
  #Enter a time in the format "12:00 AM" and it will return number of minutes from midnight
  def self.time_to_minutes(time)
    unless time.blank?
      
      #Split the time to array of [11:01, [AM/PM]]
      times = time.split(' ')
      
      #Split time to array of [11,01]
      hour_min = times[0].split(':')
      
      #Save the hour and minutes
      hour = hour_min[0].to_i
      minute = hour_min[1].to_i

      #Check to see if 12 needs to be added to the hour (PM time)
      if times[1] == "PM" and not hour == 12
        hour = hour.to_i + 12
      elsif times[1] == "AM" and hour == 12
        hour = 0
      end
        
      # Return the number of minutes
      time = 60 * hour + minute

    end
  end
  
  def self.minutes_to_pretty(time)
    if not time.nil?
      #Get the number of hours
      hours = (time / 60).truncate
    
      #We'll assume AM and check to see if hours is past noon (12)
      ext = " AM"
      if hours > 12
        hours -= 12
        ext = " PM"
      elsif hours == 0
        # This will be 12: AM
        hours = 12
      elsif hours == 12
        ext = " PM"
      end
    
      #The remainder is the number of minutes
      minutes = time % 60
    
      # prepend a zero to anything less than ten so it doesn't end up "12:9 AM"
      if minutes < 10
        minutes = "0" + minutes.to_s
      end
    
      #Return the combined string
      hours.to_s + ":" + minutes.to_s + ext
    end
  end
  
  def copy
    ts = self.dup
    ts.attributes = {:created_at => nil, :updated_at => nil}
    ts
  end
  
  def delete_all_routings
    self.routings.each do |r|
      r.destroy
    end
  end
  
  #
  def split_in_two
    middle = ((self.start_min + self.end_min)/2).ceil()
    
#    t = TimeSegment.new
#    t.start_min = self.start_min
#    t.end_min = middle
    ActiveRecord::Base.transaction do
      profile.time_segments.create(:start_min => start_min,
        :end_min => middle, :app_id => app_id)

      profile.time_segments.create(:start_min => middle + 1,
        :end_min => end_min, :app_id => app_id)    
      self.destroy
    end
    
  end
  
  def update_time(time1, time2)
    self.pretty_start = time1
    self.pretty_end = time2
    self.save
  end
  
  def out_of_range?
    start_time < 0 || end_time > 1439
  end
  
  def routing_exits
    self.routings.map(&:routing_exits).flatten
  end
  
  private
  
  # If destinations are exceeded, an error message is displayed
  def max_routing_exits
    errors.add(:base, max_destinations.error_message) if destinations_exceeded?
  end
  
  # Checks for the maximum number of routing exits allowed in the Company
  def max_number_of_routing_exits_allowed
    Company.find(app_id).max_destinations_for_time_segment
  end
  
  # Compares current number of destinations with the maximum allowed
  def destinations_exceeded?
    !max_destinations.valid?
  end
  
  def max_destinations
    @max_destinations ||= MaxDestinations.new(routing_exits.size, max_number_of_routing_exits_allowed)
  end
end
