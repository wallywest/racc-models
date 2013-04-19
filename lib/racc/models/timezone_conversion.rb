module TimezoneConversion
  #only works as an extend to Package
  
  #As represented in racc_route#day_of_week
  @@day_of_week_offset_values = { 
    :sun => 1, #Sunday
    :mon => 2, #Monday
    :tue => 3, #Tuesday
    :wed => 4, #Wednesday
    :thu => 5, #Thursday
    :fri => 6, #Friday
    :sat => 7  #Saturday
    }
  
  def self.day_of_week_offset_values
    @@day_of_week_offset_values
  end
  
  def update_package_timezone tz_name
    tz_profiles = shift_to_timezone tz_name
    update_web_tables tz_profiles
    self.update_attributes :time_zone => tz_name
  end
  
  def insert_to_racc_utc
    update_racc_routes_table @tz_profiles
  end

  def set_tz_profiles
    @tz_profiles = shift_to_timezone('UTC')
  end
  
  def shift_to_timezone tz_name
    to_timezone = ActiveSupport::TimeZone.new(tz_name)
    from_timezone = ActiveSupport::TimeZone.new(current_timezone_for_pkg)
    
    offset = standard_offset(to_timezone) - standard_offset(from_timezone)
    tz_shift_data = self.shift_package offset
  end
  
  # This always returns the standard GMT offset regardless of whether
  # or not the timezone is in DST
  def standard_offset(_timezone)
    orig_offset = _timezone.formatted_offset
    std_offset = orig_offset.to_f
    std_offset += 0.5 if orig_offset[-3..-1] == ":30"
    std_offset
  end
  
  def current_timezone_for_pkg
    self.time_zone || 'UTC'
  end
  
  def shift_package offset
    flattened_segments = self.flatten_time_segments
    flattened_segments.each do |fs|
      fs.shift_times offset
    end
    split_segments = TimezoneConversion.split_time_segments flattened_segments
    TimezoneConversion.normalize_time_segments split_segments
    profiles = TimezoneConversion.define_profiles split_segments
    merged_profiles = TimezoneConversion.merge_profiles profiles
    merged_profiles = TimezoneConversion.merge_time_segments merged_profiles
  end
  
  def update_web_tables tz_profiles
    ActiveRecord::Base.transaction do
      self.profiles.destroy_all
      tz_profiles.each_with_index do |profile, index|
        web_profile = self.profiles.create(:app_id => self.app_id, :name => "profile_#{index}") do |p|
          TimezoneConversion.day_of_week_offset_values.each do |sym, val|
            if (profile.days_of_week & (2 ** (8 - val))) > 0
              p.send("#{sym.to_s}=", true)
            end
          end
        end
        web_profile.save!
        profile.time_ranges.each do |time_range|
          web_time_segment = TimeSegment.create(:start_min => time_range.start_min, :end_min => time_range.end_min, :app_id => self.app_id, :profile_id => web_profile.id)
        
          time_range.routings.each do |routing|
            web_routing = web_time_segment.routings.create!(:percentage => routing.percentage, :app_id => self.app_id)
          
            routing.exits.each_with_index do |exit, index|
              web_routing.routing_exits.create!(:app_id => self.app_id, :call_priority => index + 1, :exit_id => exit[:exit_id], :exit_type => exit[:exit_type], :dequeue_label => exit[:dequeue_label])
            end
          end
        end
      end
    end
  end
  
  def update_racc_routes_table tz_profiles
    tz_profiles.each do |profile|
      profile.time_ranges.each do |time_range|
        time_range.routings.each do |routing|
          route = RaccRoute.create!(:route_name => self.vlabel_map.vlabel, 
                      :day_of_week => profile.days_of_week,
                      :begin_time => time_range.start_min,
                      :end_time => time_range.end_min, 
                      :destid => rand(Time.now.to_i),
                      :distribution_percentage => routing.percentage,
                      :app_id => self.app_id) #?
          routing.exits.each_with_index do |exit, i|
            RaccRouteDestinationXref.create!(
              :destination_id => exit[:exit_id],
              :exit_type => exit[:exit_type],
              :dtype => exit[:dtype],
              :transfer_lookup => exit[:transfer_lookup],
              :dequeue_label => exit[:dequeue_label],
              :route_id => route.id,
              :route_order => i + 1,
              :app_id => self.app_id)
          end
        end
      end
    end
  end
  
  def flatten_time_segments
    segments = []
    self.profiles.each do |profile|
      profile.time_segments.each do |time_segment|
        @@day_of_week_offset_values.each do |day, value|
          if profile.send(day)
            wtr = WeeklongTimeRange.new(time_segment.start_min + 1440 * (value - 1), time_segment.end_min + 1440 * (value - 1))
            time_segment.routings.each do |routing|
              routing_exits = routing.routing_exits.all(:order => "call_priority ASC")
              routing_exits.map! do |re|
                exit = Exit.new(re, re.app_id)
                transfer_lookup = if re.exit_type == "Destination" && re.exit.is_queue?
                  "O"
                else
                  ""
                end
                h = {
                  :exit_id => re.exit.id,
                  :exit_type => re.exit_type,
                  :dtype => exit.dtype,
                  :transfer_lookup => transfer_lookup,
                  :dequeue_label => re.dequeue_label
                }
              end

              routing_clone = Routing.new(routing.percentage, routing_exits)
              wtr.routings << routing_clone
            end
            segments << wtr
          end
        end
      end
    end
    return segments
  end
  
  def self.split_time_segments flattened_time_segments
    t_primes = []
    flattened_time_segments.each do |t|
      boundary = t.find_day_of_week_boundary
      t_primes << t.split!(boundary) if boundary
    end
    flattened_time_segments.concat(t_primes)
    flattened_time_segments.sort! { |x,y| x.start_min <=> y.start_min }
  end
  
  def self.normalize_time_segments time_segments
    time_segments.each do |segment|
      segment.normalize_to_week!
    end
    time_segments.sort! { |x,y| x.start_min <=> y.start_min }
  end
  
  def self.define_profiles time_segments
    profiles = []
    
    current_day_index = 0
    current_profile = nil
    time_segments.each do |segment|
      unless current_day_index == segment.day_of_week_index
        current_day_index = segment.day_of_week_index
        profiles << current_profile = TimezoneConversion::Profile.new
        current_profile.add_day_of_week(8 - current_day_index)
      end
      segment.normalize_to_day!
      current_profile.time_ranges << segment
    end
    return profiles
  end
  
  def self.merge_profiles profiles
    merged_profiles = []
    while not profiles.empty?
      next_profile = profiles.shift
      #   match_profile = next_profile.find_match(merged_profiles)
      match_profile = nil
      merged_profiles.each do |p|
        if p.time_ranges == next_profile.time_ranges
          match_profile = p
          break
        end
      end
      if (match_profile)
        #glaring assumption that next profile has only 1 day of week
        match_profile.add_day_of_week(Math.log(next_profile.days_of_week) / Math.log(2))
      else 
        merged_profiles << next_profile
      end
    end
      
    return merged_profiles
  end

  def self.merge_time_segments profiles
    profiles.each { |p| p.merge_time_ranges! }
    return profiles
  end
  
  class WeeklongTimeRange
    
    attr_accessor :start_min, :end_min, :routings
    
    def initialize(start_min = 0, end_min = 0, routings = [])
      @start_min = start_min
      @end_min = end_min
      @routings = routings
    end
    
    def shift_times utc_offset
      @start_min += 60 * utc_offset
      @end_min += 60 * utc_offset
    end
    
    def split! min
      if (@start_min + 1..@end_min - 1).include? min
        other_routings = @routings.collect {|r| r.dup}
        other_time_range = WeeklongTimeRange.new(min, @end_min, other_routings)
        self.end_min = min - 1
        return other_time_range
      else
        raise ArgumentError.new("Split minute must be less than the range's end time and greater than the range's start time.")
      end
    end
    
    def find_day_of_week_boundary
      nearest_boundary = ((@start_min + 1440) / 1440).floor * 1440
      time_range = (@start_min..@end_min)
      if time_range.include?(nearest_boundary) && time_range.include?(nearest_boundary - 1)
        return nearest_boundary
      else
        return nil
      end
    end
    
    def normalize_to_week!
      normalize! 10080
    end
    
    def normalize_to_day!
      normalize! 1440
    end
    
    def day_of_week_index
      ((@start_min + 1440) / 1440).floor
    end
    
    def merge! other
      if @end_min >= other.start_min - 1
        @end_min = [@end_min, other.end_min].max
      else
        raise ArgumentError.new("Merging two time ranges requires that the time ranges be adjacent to each other.")
      end
    end
  
    def ==(other)
      WeeklongTimeRange == other.class && @start_min == other.start_min && @end_min == other.end_min && @routings == other.routings
    end
    
    private
    
    def normalize!(amt)
      @start_min = (@start_min + amt) % amt
      @end_min = (@end_min + amt) % amt
    end
  end
  
  class Routing
    
    attr_accessor :percentage, :exits
    
    def initialize(percentage = 100, exits = [])
      @percentage = percentage
      @exits = exits
    end
    
    def clone
      Routing.new(@percentage, @exits.dup)
    end
    
    def ==(other)
      Routing == other.class && @percentage == other.percentage && @exits == other.exits
    end
  end
  
  class Profile
    attr_accessor :time_ranges
    attr_reader :days_of_week
    
    def initialize(time_ranges = [])
      @time_ranges = time_ranges
      @days_of_week = 0
    end
    
    def add_day_of_week val
      @days_of_week |= 2 ** val.to_i
    end
    
    def remove_day_of_week val
      @days_of_week &=  255 - (2 ** val.to_i)
    end
    
    def merge_time_ranges!
      return if @time_ranges.empty?
      
      merged_time_ranges = [@time_ranges.shift]
      while not @time_ranges.empty?
        prev_time_range = merged_time_ranges.last
        next_time_range = @time_ranges.shift
        adjacent = prev_time_range.end_min == next_time_range.start_min - 1
        if adjacent && next_time_range.routings == prev_time_range.routings
          prev_time_range.merge! next_time_range
        else
          merged_time_ranges << next_time_range
        end
      end
      @time_ranges = merged_time_ranges
    end
  end
  
end
