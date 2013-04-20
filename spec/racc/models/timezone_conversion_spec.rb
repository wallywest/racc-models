require 'spec_helper'

# Shifting tests
# Every day of the week
#      - test at the minute boundary of a shift (11:59pm, 12:00pm, 12:01pm, shift forward and backward an hour)
#     
# mwood feedback

describe TimezoneConversion do
  
  it "should be included in Packages" do
    
    Package.included_modules.should include(TimezoneConversion)
    
  end
  
  describe "update_package_timezone" do
    before(:each) do
      @package = FactoryGirl.build(:package, :time_zone => "Central Time (US & Canada)")      
    end
    
    it "shifts the time zone data and updates the package" do
      mock_tz_data = mock('tz')
      @package.should_receive(:shift_to_timezone).with('UTC').and_return mock_tz_data
      @package.should_receive(:update_web_tables).with(mock_tz_data)
      
      @package.update_package_timezone('UTC')
    end
    
    it "updates the package's time zone field" do
      @package.update_package_timezone('UTC')
      @package.time_zone.should == 'UTC'
    end
    
  end
  
  describe "set_tz_profiles" do
    
    it "should return a shift_to_timezone object" do
      package = FactoryGirl.build(:package, :time_zone => "Central Time (US & Canada)")
      mock_tz_data = mock('tz')
      package.should_receive(:shift_to_timezone).with("UTC").and_return mock_tz_data
      
      package.set_tz_profiles
    end
  end

  describe 'insert_to_racc_utc' do
    it "should update the RACC tables" do
      package = FactoryGirl.build(:package, :time_zone => "Central Time (US & Canada)")
      package.should_receive(:update_racc_routes_table)

      package.insert_to_racc_utc
    end
  end
  
  describe "shift to timezone" do
    
    it "shifts forward one hour" do
      test_time_shift("Eastern Time (US & Canada)", "Central Time (US & Canada)", 1.0)
    end
    
    it "shifts back one hour" do
      test_time_shift("Central Time (US & Canada)", "Eastern Time (US & Canada)", -1.0)
    end
    
    it "shifts by zero" do
      test_time_shift("Eastern Time (US & Canada)", "Eastern Time (US & Canada)", 0.0)
    end
    
    it "shifts fractionally" do
      test_time_shift("Darwin", "Hawaii", 19.5)
    end
    
    it "shifts by maximum possible offset" do
      test_time_shift("Nuku'alofa", "International Date Line West", 24.0)
    end
    
    it "shifs from a non-DST zone to a non-DST zone" do
      test_time_shift("UTC", "Hawaii", 10.0)
    end

    it "shifts from a DST zone to a non-DST zone" do
      test_time_shift("Hawaii", "Central Time (US & Canada)", -4.0)
    end
    
    it "shifts from a non-DST zone to a DST zone" do
      test_time_shift("Central Time (US & Canada)", "UTC", -6.0)
    end

    def test_time_shift(_to, _from, _expected_offset)
      package = FactoryGirl.build(:package, :time_zone => _from)      
      package.should_receive(:shift_package).with(_expected_offset)
      package.shift_to_timezone(_to)
    end
  
  end
  
  describe "standard_offset" do
    before(:each) do
      @package = FactoryGirl.build(:package)
    end
    
    it "returns the standard offset for a timezone" do
      tz = ActiveSupport::TimeZone.new("Central Time (US & Canada)")
      @package.standard_offset(tz).should == -6.0
      
      tz = ActiveSupport::TimeZone.new("Paris")
      @package.standard_offset(tz).should == 1.0

      tz = ActiveSupport::TimeZone.new("Hawaii")
      @package.standard_offset(tz).should == -10.0      
      
      tz = ActiveSupport::TimeZone.new("UTC")
      @package.standard_offset(tz).should == 0.0      
    end
    
    it "returns a fractional standard offset" do
      tz = ActiveSupport::TimeZone.new("Darwin")
      @package.standard_offset(tz).should == 9.5

      tz = ActiveSupport::TimeZone.new("New Delhi")
      @package.standard_offset(tz).should == 5.5            
    end
    
  end
  
  describe "current timezone for pkg" do
    
    it "returns the timezone on the package" do
      tz = "Eastern Time (US & Canada)"
      @package = FactoryGirl.build(:package, :time_zone => tz)
      @package.current_timezone_for_pkg.should == tz
    end
    
    it "returns 'UTC' if there is no timezone on the package" do
      @package = FactoryGirl.build(:package, :time_zone => nil)
      @package.current_timezone_for_pkg.should == 'UTC'
    end
    
  end
  
  describe "updating web tables" do
    before :each do
      FactoryGirl.create(:company)
      @pkg = FactoryGirl.create(:package, :time_zone => "Central Time (US & Canada)")
      FactoryGirl.create(:destination_property)
    end
    
    it "should result in a direct route identical to the original apart from profile names" do
      profile = FactoryGirl.create(:profile, :sun => true, :mon => true, :tue => true, :wed => true, :thu => true, :fri => true, :sat => true, :package => @pkg)
      
      ts = FactoryGirl.create(:time_segment, :profile => profile)
      r = FactoryGirl.create(:routing, :time_segment => ts)
      destination = FactoryGirl.create(:destination)
      rd = FactoryGirl.create(:routing_exit, :routing => r, :exit => destination)

      @pkg.reload
      merge_data = @pkg.shift_package -5
      @pkg.update_web_tables(merge_data)
      
      web_profile = @pkg.profiles[0]
      web_profile.sun.should == true
      web_profile.mon.should == true
      web_profile.tue.should == true
      web_profile.wed.should == true
      web_profile.thu.should == true
      web_profile.fri.should == true
      web_profile.sat.should == true
      web_profile.should_not be_new_record
      
      web_ts = web_profile.time_segments[0]
      web_ts.start_min.should == 0
      web_ts.end_min.should == 1439
      web_ts.should_not be_new_record
      
      web_routing = web_ts.routings[0]
      web_routing.percentage.should == 100
      web_routing.should_not be_new_record
      
      web_routing_exit = web_routing.routing_exits[0]
      web_routing_exit.exit_id.should == destination.id
      web_routing_exit.should_not be_new_record
    end
    
    it "should result in a new set of profiles covering the same times and routings, but shifted a few hours" do
      after_hours_destination = FactoryGirl.create(:destination)
      business_hours_destination = FactoryGirl.create(:destination)
      
      weekend_profile = FactoryGirl.create(:profile, :sun => true, :sat => true, :package => @pkg)
      all_day_time_segment = FactoryGirl.create(:time_segment, :profile => weekend_profile)
      r = FactoryGirl.create(:routing, :time_segment => all_day_time_segment)
      FactoryGirl.create(:routing_exit, :routing => r, :exit => after_hours_destination)
      
      weekday_profile = FactoryGirl.create(:profile, :mon => true, :tue => true, :wed => true, :thu => true, :fri => true, :package => @pkg)
      weekday_before_nine = FactoryGirl.create(:time_segment, :end_min => 539, :profile => weekday_profile)
      weekday_nine_to_five = FactoryGirl.create(:time_segment, :start_min => 540, :end_min => 1019, :profile => weekday_profile)
      weekday_after_five = FactoryGirl.create(:time_segment, :start_min => 1020, :profile => weekday_profile)
      r = FactoryGirl.create(:routing, :time_segment => weekday_before_nine)
      FactoryGirl.create(:routing_exit, :routing => r, :exit => after_hours_destination)
      r = FactoryGirl.create(:routing, :time_segment => weekday_nine_to_five)
      FactoryGirl.create(:routing_exit, :routing => r, :exit => business_hours_destination)
      r = FactoryGirl.create(:routing, :time_segment => weekday_after_five)
      FactoryGirl.create(:routing_exit, :routing => r, :exit => after_hours_destination)
      
      @pkg.reload
      
      merge_data = @pkg.shift_package -5
      @pkg.update_web_tables(merge_data)
      
      @pkg.profiles.size.should == 2
      web_profile = @pkg.profiles[0]
      web_profile.sun.should == true
      web_profile.mon.should == false
      web_profile.tue.should == false
      web_profile.wed.should == false
      web_profile.thu.should == false
      web_profile.fri.should == false
      web_profile.sat.should == true
      web_profile.should_not be_new_record
      
      web_ts = web_profile.time_segments[0]
      web_ts.start_min.should == 0
      web_ts.end_min.should == 1439
      web_ts.should_not be_new_record
      
      web_routing = web_ts.routings[0]
      web_routing.percentage.should == 100
      web_routing.should_not be_new_record
      
      web_routing_exit = web_routing.routing_exits[0]
      web_routing_exit.exit_id.should == after_hours_destination.id
      web_routing_exit.should_not be_new_record
      
      web_profile = @pkg.profiles[1]
      web_profile.sun.should == false
      web_profile.mon.should == true
      web_profile.tue.should == true
      web_profile.wed.should == true
      web_profile.thu.should == true
      web_profile.fri.should == true
      web_profile.sat.should == false
      web_profile.should_not be_new_record
      
      web_ts = web_profile.time_segments[1]
      web_ts.start_min.should == 240
      web_ts.end_min.should == 719
      web_ts.should_not be_new_record
      
      web_routing = web_ts.routings[0]
      web_routing.percentage.should == 100
      web_routing.should_not be_new_record
      
      web_routing_exit = web_routing.routing_exits[0]
      web_routing_exit.exit_id.should == business_hours_destination.id
      web_routing_exit.should_not be_new_record
    end

    it 'destroys all existing sub-package objects' do
      profile = FactoryGirl.create(:profile, :sun => true, :mon => true, :tue => true, :wed => true, :thu => true, :fri => true, :sat => true, :package => @pkg)
      
      ts = FactoryGirl.create(:time_segment, :profile => profile)
      r = FactoryGirl.create(:routing, :time_segment => ts)
      destination = FactoryGirl.create(:destination)
      rd = FactoryGirl.create(:routing_exit, :routing => r, :exit => destination)

      @pkg.reload
      merge_data = @pkg.shift_package -5
      @pkg.update_web_tables(merge_data)

      Profile.exists?(profile.id).should be_false
      TimeSegment.exists?(ts.id).should be_false
      Routing.exists?(r.id).should be_false
      RoutingExit.exists?(rd.id).should be_false
    end
  end
  
  describe "updating racc routes table" do
    before :each do
      FactoryGirl.create(:company)
      @pkg = FactoryGirl.create(:package)
      @dest_prop = FactoryGirl.create(:destination_property)
    end
    
    it "should create a racc route for each routing within the package" do
      dest1 = FactoryGirl.create(:destination)
      dest2 = FactoryGirl.create(:destination)
      
      routing_exit1 = {:exit_id => dest1.id, :exit_type => "Destination", :dtype => "D", :dequeue_label => '', :transfer_lookup => @dest_prop.transfer_lookup}
      routing_exit2 = {:exit_id => dest2.id, :exit_type => "Destination", :dtype => "D", :dequeue_label => '', :transfer_lookup => @dest_prop.transfer_lookup}
      
      time_range1 = TimezoneConversion::WeeklongTimeRange.new(0, 799)
      routing = TimezoneConversion::Routing.new(100, [routing_exit1])
      time_range1.routings << routing

      time_range2 = TimezoneConversion::WeeklongTimeRange.new(800, 1439)
      routing2 = TimezoneConversion::Routing.new(100, [routing_exit2, routing_exit1])
      time_range2.routings << routing2
      
      profile = TimezoneConversion::Profile.new([time_range1, time_range2])
      (1..7).each do |i|
        profile.add_day_of_week(i)
      end
      
      @pkg.update_racc_routes_table [profile]
      
      routes = RaccRoute.all
      routes.size.should == 2
      routes[0].day_of_week.should == 254
      routes[0].begin_time.should == 0
      routes[0].end_time.should == 799
      routes[0].distribution_percentage.should == 100
      routes[0].racc_route_destination_xrefs[0].destination_id.should == dest1.id

      routes[1].day_of_week.should == 254
      routes[1].begin_time.should == 800
      routes[1].end_time.should == 1439
      routes[1].distribution_percentage.should == 100
      route_dest_xrefs = routes[1].racc_route_destination_xrefs.all(:order => 'route_order ASC')
      route_dest_xrefs[0].route_order.should == 1
      route_dest_xrefs[0].destination_id.should == dest2.id
      route_dest_xrefs[0].dtype.should == "D"
      route_dest_xrefs[1].route_order.should == 2
      route_dest_xrefs[1].destination_id.should == dest1.id
      route_dest_xrefs[1].dtype.should == "D"
    end
  end
  
  describe "flattening time segments" do
    
    before :each do
      @company = FactoryGirl.create(:company)
      @package = FactoryGirl.create(:package, :time_zone => "Central Time (US & Canada)")
    end
    
    it "should return a list of time ranges representing a time segment's place on a timeline of the week" do
      
      @weekday_profile = FactoryGirl.create(:profile, :mon => true, :tue => true, :wed => true, :thu => true, :fri => true, :package => @package)
      @weekend_profile = FactoryGirl.create(:profile, :sat => true, :sun => true, :package => @package)

      @weekend_before_noon = FactoryGirl.create(:time_segment, :start_min => 0, :end_min => 719, :profile => @weekend_profile)
      @weekend_after_noon = FactoryGirl.create(:time_segment, :start_min => 720, :end_min => 1439, :profile => @weekend_profile)

      @package.reload
      
      flattened_ranges = @package.flatten_time_segments
      
      #weekend before noon
      flattened_ranges.should include(TimezoneConversion::WeeklongTimeRange.new(0, 719))
      flattened_ranges.should include(TimezoneConversion::WeeklongTimeRange.new(8640, 9359))
      
      #weekend after noon
      flattened_ranges.should include(TimezoneConversion::WeeklongTimeRange.new(720, 1439))
      flattened_ranges.should include(TimezoneConversion::WeeklongTimeRange.new(9360, 10079))
    end
    
    it "can handle overlapping time segments" do
      @profile = FactoryGirl.create(:profile, :sun => true, :package => @package)

      @ts1 = FactoryGirl.create(:time_segment, :start_min => 0, :end_min => 819, :profile => @profile)
      @ts2 = FactoryGirl.create(:time_segment, :start_min => 620, :end_min => 1439, :profile => @profile)
      
      @package.reload
      
      flattened_ranges = @package.flatten_time_segments
      
      flattened_ranges.should include(TimezoneConversion::WeeklongTimeRange.new(0, 819))
      flattened_ranges.should include(TimezoneConversion::WeeklongTimeRange.new(620, 1439))
    end
    
    it "should track the routing information from the original time segments" do
      @dest_prop = FactoryGirl.create(:destination_property)
      @dest1 = FactoryGirl.create(:destination)
      @dest2 = FactoryGirl.create(:destination)
      
      @profile = FactoryGirl.create(:profile, :sun => true, :package => @package)
      @ts = FactoryGirl.create(:time_segment, :start_min => 0, :end_min => 819, :profile => @profile)
      @routing = FactoryGirl.create(:routing, :percentage => 50, :time_segment => @ts)
      @routing_exit1 = FactoryGirl.create(:routing_exit, :call_priority => 2, :exit => @dest1, :routing => @routing)
      @routing_exit2 = FactoryGirl.create(:routing_exit, :call_priority => 1, :exit => @dest2, :routing => @routing)
      
      @package.reload
      
      flattened_ranges = @package.flatten_time_segments
      
      routing = flattened_ranges.first.routings.first
      routing.percentage.should == 50
      routing.exits[0].should == {:exit_id => @dest2.id, :exit_type => "Destination", :dtype => "D", :dequeue_label => @routing_exit2.dequeue_label, :transfer_lookup => ''}
      routing.exits[1].should == {:exit_id => @dest1.id, :exit_type => "Destination", :dtype => "D", :dequeue_label => @routing_exit1.dequeue_label, :transfer_lookup => ''}
    end
    
    it 'will set the transfer_lookup field when routing to a queue' do
      @vlabel = FactoryGirl.create(:vlabel_map)
      @dest_prop = FactoryGirl.create(:destination_property, :destination_property_name => Destination::QUEUE_DESTINATION_PROPERTY)
      @dest1 = FactoryGirl.create(:destination, :destination_property_name => Destination::QUEUE_DESTINATION_PROPERTY)
      @profile = FactoryGirl.create(:profile, :sun => true, :package => @package)
      @ts = FactoryGirl.create(:time_segment, :start_min => 0, :end_min => 819, :profile => @profile)
      @routing = FactoryGirl.create(:routing, :percentage => 50, :time_segment => @ts)
      @routing_exit1 = FactoryGirl.create(:routing_exit, :call_priority => 1, :exit => @dest1, :routing => @routing, :dequeue_label => @vlabel.vlabel)

      @package.reload
      
      flattened_ranges = @package.flatten_time_segments
      
      routing = flattened_ranges.first.routings.first
      routing.exits[0].should == {:exit_id => @dest1.id, :exit_type => "Destination", :dtype => "D", :dequeue_label => @routing_exit1.dequeue_label, :transfer_lookup => 'O'}
    end
  end
  
  describe "splitting time segments" do
    it "returns a list of time segments split at day-of-week and week boundaries" do
      time_segments = []
      time_segments << TimezoneConversion::WeeklongTimeRange.new(-400, 800)
      time_segments << TimezoneConversion::WeeklongTimeRange.new(801, 1200)
      time_segments << TimezoneConversion::WeeklongTimeRange.new(1201, 2400)
      
      split_time_ranges = TimezoneConversion.split_time_segments time_segments
      split_time_ranges[0].end_min.should == -1
      split_time_ranges[1].start_min.should == 0
      split_time_ranges[3].end_min.should == 1439
      split_time_ranges[4].start_min.should == 1440
    end
  end
  
  describe "normalizing time segments" do
    it "attaches a time range falling before the beginning of the week to the end" do
      time_segments = []
      time_segments << TimezoneConversion::WeeklongTimeRange.new(-400, -1)
      time_segments << TimezoneConversion::WeeklongTimeRange.new(0, 1200)
      
      normalized_segments = TimezoneConversion.normalize_time_segments time_segments
      normalized_segments[1].start_min.should == 9680
      normalized_segments[1].end_min.should == 10079
    end
  
    it "attaches a time range falling after the end of the week to the beginning" do
      time_segments = []
      time_segments << TimezoneConversion::WeeklongTimeRange.new(101, 1200)
      time_segments << TimezoneConversion::WeeklongTimeRange.new(10080, 10180)
      
      normalized_segments = TimezoneConversion.normalize_time_segments time_segments
      normalized_segments[0].start_min.should == 0
      normalized_segments[0].end_min.should == 100
    end
  end
  
  describe "define_profiles" do
    
    it "creates a profile per day" do
      time_segments = []
      time_segments << day1 = TimezoneConversion::WeeklongTimeRange.new(0, 1439)
      time_segments << day2 = TimezoneConversion::WeeklongTimeRange.new(1440, 2879)
      time_segments << day3 = TimezoneConversion::WeeklongTimeRange.new(2880, 4319)
      
      profiles = TimezoneConversion.define_profiles(time_segments)
            
      profiles[0].time_ranges.should include(day1)
      profiles[0].days_of_week.should == 128
      profiles[1].time_ranges.should include(day2)
      profiles[1].days_of_week.should == 64
      profiles[2].time_ranges.should include(day3)
      profiles[2].days_of_week.should == 32
      
    end
    
    it "does not create a profile for days with no ranges scheduled" do
      time_segments = []
      time_segments << sunday = TimezoneConversion::WeeklongTimeRange.new(0, 1439)
      
      time_segments << tuesday = TimezoneConversion::WeeklongTimeRange.new(2880, 3000)
      
      profiles = TimezoneConversion.define_profiles(time_segments)
      
      profiles[0].time_ranges.should include(sunday)
      profiles[0].days_of_week.should == 128
      profiles[1].time_ranges.should include(tuesday)
      profiles[1].days_of_week.should == 32
      profiles.size.should == 2
    end
    
    it "puts multiple time ranges that take place on the same day into the same profile" do
      time_segments = []
      
      time_segments << tuesday1 = TimezoneConversion::WeeklongTimeRange.new(2880, 3000)
      time_segments << tuesday2 = TimezoneConversion::WeeklongTimeRange.new(3001, 4319)
      
      profiles = TimezoneConversion.define_profiles(time_segments)
      
      profiles[0].time_ranges.should include(tuesday1)
      profiles[0].time_ranges.should include(tuesday2)
      profiles[0].days_of_week.should == 32
    end
    
    it "noramlizes a time range to the time of day" do
      time_segments = [TimezoneConversion::WeeklongTimeRange.new(2880, 3000)]
      
      profiles = TimezoneConversion.define_profiles(time_segments)
      
      profiles[0].time_ranges[0].start_min.should == 0
      profiles[0].time_ranges[0].end_min.should == 120
    end
    
  end
  
  describe "merge profiles" do
    
    it "combines profiles for days that have identical ranges and routings" do
      
      day1 = TimezoneConversion::WeeklongTimeRange.new(0, 1439)
      routing = TimezoneConversion::Routing.new(100, [12345])
      day1.routings << routing

      day2 = TimezoneConversion::WeeklongTimeRange.new(0, 1439)
      routing2 = routing.clone
      day2.routings << routing2
      
      
      profile1 = TimezoneConversion::Profile.new([day1])
      profile1.add_day_of_week(7)
      profile2 = TimezoneConversion::Profile.new([day2])
      profile2.add_day_of_week(6)
      
      merged_profiles = TimezoneConversion.merge_profiles([profile1, profile2])
      merged_profiles.size.should == 1
      merged_profiles[0].time_ranges[0].should == day1
      merged_profiles[0].days_of_week.should == 192
      
    end
    
    it "leaves the others alone" do
      day1 = TimezoneConversion::WeeklongTimeRange.new(0, 1439)
      routing = TimezoneConversion::Routing.new(100, [12345])
      day1.routings << routing

      day2 = TimezoneConversion::WeeklongTimeRange.new(0, 1439)
      routing2 = TimezoneConversion::Routing.new(100, [569103])
      day2.routings << routing2
      
      profile1 = TimezoneConversion::Profile.new([day1])
      profile1.add_day_of_week(7)
      profile2 = TimezoneConversion::Profile.new([day2])
      profile2.add_day_of_week(6)
      
      
      merged_profiles = TimezoneConversion.merge_profiles([profile1, profile2])
      merged_profiles.size.should == 2
      merged_profiles[0].time_ranges[0].should == day1
      merged_profiles[1].time_ranges[0].should == day2
      
      merged_profiles[0].days_of_week.should == 128
      merged_profiles[1].days_of_week.should == 64
    end
    
  end
  
  describe "merge time segments" do
    it "invokes merge_time_ranges! on each profile" do
      profile1 = TimezoneConversion::Profile.new
      profile2 = TimezoneConversion::Profile.new
      
      profile1.should_receive(:merge_time_ranges!).once
      profile2.should_receive(:merge_time_ranges!).once
      
      TimezoneConversion.merge_time_segments([profile1, profile2])
    end
  end
  
  describe TimezoneConversion::WeeklongTimeRange do
    
    describe "construction" do
      
      it "defaults values to 0" do
        wtr = TimezoneConversion::WeeklongTimeRange.new
        wtr.start_min.should == 0
        wtr.end_min.should == 0
      end
      
      it "takes arguments for start and end minutes" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(120, 719)
        wtr.start_min.should == 120
        wtr.end_min.should == 719
      end
      
    end
    
    describe "equality testing" do
      it "is never equal for objects of other classes" do
        wtr = TimezoneConversion::WeeklongTimeRange.new
        wtr.should_not == "a string"
      end
      
      it "is equal to other time ranges with the same values and routings" do
        wtr1 = TimezoneConversion::WeeklongTimeRange.new(10, 50)
        rt1 = TimezoneConversion::Routing.new(100, [235, 34, 13])
        wtr1.routings << rt1
        
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(10, 50)
        rt2 = TimezoneConversion::Routing.new(100, [235, 34, 13])
        wtr2.routings << rt2
        
        wtr1.should == wtr2
      end
      
      it "is not equal to other time ranges with different values" do
        wtr1 = TimezoneConversion::WeeklongTimeRange.new(10, 50)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(20, 100)
        wtr1.should_not == wtr2
      end 
      
      
      it "is not equal to other time ranges with the same values but different routings" do
        wtr1 = TimezoneConversion::WeeklongTimeRange.new(10, 50)
        rt1 = TimezoneConversion::Routing.new(100, [235, 34, 13])
        wtr1.routings << rt1
        
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(10, 50)
        rt2 = TimezoneConversion::Routing.new(100, [11, 521, 1113])
        wtr2.routings << rt2
        
        wtr1.should_not == wtr2
      end
    end
    
    describe "shift_times" do
      it "shifts the start and end time by 60 * utc_offset" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 819)
        wtr.shift_times(-5)
        wtr.start_min.should == -300
        wtr.end_min .should == 519
      end
                                
      it "can shift fractional offsets" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 819)
        wtr.shift_times(-5.5)
        wtr.start_min.should == -330
        wtr.end_min .should == 489
        
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 819)
        wtr.shift_times(-5.25)
        wtr.start_min.should == -315
        wtr.end_min .should == 504
      end
      
    end
    
    
    describe "split" do
      it "fully covers the original time range" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 819)
        wtr2 = wtr.split! 400
        
        wtr.start_min.should == 0
        wtr.end_min.should == 399
        wtr2.start_min.should == 400
        wtr2.end_min.should == 819
      end
      
      it "does not split the time range if the target minute does not fall into the time range" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 819)
        lambda { wtr.split! 1000 }.should raise_error(ArgumentError, "Split minute must be less than the range's end time and greater than the range's start time.")
      end
      
      it "it will not make a split that results in a time range of 0 size" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 1)
        lambda { wtr.split! 1}.should raise_error(ArgumentError, "Split minute must be less than the range's end time and greater than the range's start time.")
        lambda { wtr.split! 0}.should raise_error(ArgumentError, "Split minute must be less than the range's end time and greater than the range's start time.")
      end
      
      it "attaches a set of cloned routings to the split time ranges" do
        routing = TimezoneConversion::Routing.new(50, [9000])
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 819, [routing])
        wtr2 = wtr.split! 400
        
        wtr.routings.first.should == routing
        wtr2.routings.first.should == routing
        
        wtr2.routings.first.percentage = 100
        wtr.routings.first.percentage.should == 50
      end
    end
    
    describe "find day of week boundary" do
      it "returns the boundary minute for a day of the week" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(-1, 819)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(1500, 2900)
        wtr3 = TimezoneConversion::WeeklongTimeRange.new(10000, 10100)
        
        wtr.find_day_of_week_boundary.should == 0
        wtr2.find_day_of_week_boundary.should == 2880
        wtr3.find_day_of_week_boundary.should == 10080
      end
      
      it "returns nil if no day of week boundaries are found" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(-400, -1)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(1500, 2800)
        wtr3 = TimezoneConversion::WeeklongTimeRange.new(10100, 10200)
        
        wtr.find_day_of_week_boundary.should == nil
        wtr2.find_day_of_week_boundary.should == nil
        wtr3.find_day_of_week_boundary.should == nil
      end
    end
    
    describe "normalize_to_week!" do
      it "leaves a time range that is not out of range as is" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 1200)
        wtr.normalize_to_week!
        
        wtr.start_min.should == 0
        wtr.end_min.should == 1200
      end
      
      it "changes a time range out of range at the beginning of the week to the end of the week" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(-400, -1)
        wtr.normalize_to_week!
        
        wtr.start_min.should == 9680
        wtr.end_min.should == 10079
      end
      
      it "changes a time range out of range at the end of the week to the beginning of the week" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(10080, 10180)
        wtr.normalize_to_week!
        
        wtr.start_min.should == 0
        wtr.end_min.should == 100
      end
    end
    
    describe "normalize_to_day" do
      it "leaves a time range that is not out of range as is" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 1200)
        wtr.normalize_to_day!
        
        wtr.start_min.should == 0
        wtr.end_min.should == 1200
      end
      
      it "changes a time range out of range at the beginning of the day to the end of the day" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(-400, -1)
        wtr.normalize_to_day!
        
        wtr.start_min.should == 1040
        wtr.end_min.should == 1439
      end
      
      it "changes a time range out of range at the end of the week to the beginning of the week" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(10080, 10180)
        wtr.normalize_to_day!
        
        wtr.start_min.should == 0
        wtr.end_min.should == 100
      end
    end
    
    describe "day_of_week_index" do
      it "returns a number based on the day of week in which it occurs, Sun-Sat => 1-7" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 1200)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(10078, 10079)
        wtr.day_of_week_index.should == 1
        wtr2.day_of_week_index.should == 7
      end
      
      it "leaves you SOL if the time segment spans more than 1 day" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 10079)
        wtr.day_of_week_index.should == 1
      end
    end
    
    describe "merge!" do
      it "merges two adjacent time ranges to fully cover the time of both" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 1200)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(1201, 1439)
        
        wtr.merge!(wtr2)
        wtr.start_min.should == 0
        wtr.end_min.should == 1439
      end
      
      it "merges two time ranges if the time they cover overlaps" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 1200)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(1000, 1439)
        
        wtr.merge!(wtr2)
        wtr.start_min.should == 0
        wtr.end_min.should == 1439
      end
      
      it "merges two time ranges if the first fully covers the second" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 1200)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(1000, 1199)
        
        wtr.merge!(wtr2)
        wtr.start_min.should == 0
        wtr.end_min.should == 1200
      end
      
      it "raises an ArgumentError if the time ranges are not adjacent" do
        wtr = TimezoneConversion::WeeklongTimeRange.new(0, 1200)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(1202, 1439)

        lambda { wtr.merge!(wtr2) }.should raise_error(ArgumentError, "Merging two time ranges requires that the time ranges be adjacent to each other.")
      end
    end
    
  end
  
  describe TimezoneConversion::Routing do
    describe "construction" do
      it "defaults initial values to 100 and empty array" do
        routing = TimezoneConversion::Routing.new
        routing.percentage.should == 100
        routing.exits.should be_empty
      end
      
      it "takes arguments for percentage and destinations" do
        routing = TimezoneConversion::Routing.new(50, [1337])
        routing.percentage.should == 50
        routing.exits.first.should == 1337
      end
    end
    
    describe "equality testing" do
      it "is never equal for objects of other classes" do
        routing = TimezoneConversion::Routing.new
        routing.should_not == "a string"
      end
      
      it "is equal to other routings with the same values" do
        routing1 = TimezoneConversion::Routing.new(75, [9000])
        routing2 = TimezoneConversion::Routing.new(75, [9000])
        routing1.should == routing2
      end
      
      it "is not equal to other routings with different values" do
        routing1 = TimezoneConversion::Routing.new(50, [1337, 9000])
        routing2 = TimezoneConversion::Routing.new(60, [1337, 9000])
        routing3 = TimezoneConversion::Routing.new(50, [9000, 1337])
        
        routing1.should_not == routing2
        routing1.should_not == routing3
      end 
    end
    
    describe "clone" do
      it "creates a copy of the original routing with identical values" do
        routing = TimezoneConversion::Routing.new(50, [1337, 9000])
        routing2 = routing.clone
        
        routing.percentage.should == routing2.percentage
        routing.exits.should == routing2.exits
      end
      
      it "ensures that the original and cloned objects are independent of each other" do
        routing = TimezoneConversion::Routing.new(50, [1337, 9000])
        routing2 = routing.clone
        
        routing2.percentage = 75
        routing2.exits << 1
        
        routing.percentage.should_not == routing2.percentage
        routing.exits.should_not == routing2.exits
      end
    end
  end
  
  describe TimezoneConversion::Profile do
    
    describe "days_of_week bitfield" do
      it "is 0 when no days are set" do
        profile = TimezoneConversion::Profile.new
        profile.days_of_week.should == 0
      end
      
      it "is 254 when all days are set" do
        profile = TimezoneConversion::Profile.new
        profile.add_day_of_week(1)
        profile.add_day_of_week(2)
        profile.add_day_of_week(3)
        profile.add_day_of_week(4)
        profile.add_day_of_week(5)
        profile.add_day_of_week(6)
        profile.add_day_of_week(7)
        profile.days_of_week.should == 254
      end
      
      it "starts counting at 2 so that 2 ^ (day of week) counts day of week starting at 1" do
        profile = TimezoneConversion::Profile.new
        profile.add_day_of_week(1)
        profile.days_of_week.should == 2
      end
    end
    
    describe "add day of week" do 
      it "takes a day index (7 - 1 => Sun -> Sat) and adds the day it represents to the list covered by this profile" do
        profile = TimezoneConversion::Profile.new
        profile.add_day_of_week(6)
        profile.days_of_week.should == 64
        
        profile = TimezoneConversion::Profile.new
        profile.add_day_of_week(1)
        profile.days_of_week.should == 2
        
        profile.add_day_of_week(4)
        profile.days_of_week.should == 18
      end
      
      it "does not validate inputs" do
        profile = TimezoneConversion::Profile.new
        profile.add_day_of_week(256)
        profile.days_of_week.should == 115792089237316195423570985008687907853269984665640564039457584007913129639936
        
        profile = TimezoneConversion::Profile.new
        profile.add_day_of_week(-1)
        profile.days_of_week.should == 0
        
        profile = TimezoneConversion::Profile.new
        profile.add_day_of_week(0)
        profile.days_of_week.should == 1
        
      end
    end
    
    describe "remove day of week" do
      it "takes a day index (7 - 1 => Sun -> Sat) and removes the day it represents to the list covered by this profile" do
        profile = TimezoneConversion::Profile.new
        profile.add_day_of_week(7)
        profile.add_day_of_week(6)
        profile.add_day_of_week(5)
        
        profile.remove_day_of_week(6)
        profile.days_of_week.should == 160
      end
      
      it "will silently accept removing a day that is already removed" do
        profile = TimezoneConversion::Profile.new
        profile.remove_day_of_week(2)
        profile.days_of_week.should == 0
      end
      
      it "does not validate inputs" do
        profile = TimezoneConversion::Profile.new
        profile.remove_day_of_week(256)
        profile.days_of_week.should == 0
        
        profile = TimezoneConversion::Profile.new
        profile.remove_day_of_week(-1)
        profile.days_of_week.should == 0
      end
      
    end
    
    describe "merge_time_ranges!" do
      it "combines time ranges that have identical routings and are adjacent to one another" do
        routing1 = TimezoneConversion::Routing.new(50, [1337, 9000])
        routing2 = TimezoneConversion::Routing.new(50, [1337, 9000])
        
        wtr1 = TimezoneConversion::WeeklongTimeRange.new(0, 1200, routing1)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(1201, 1439, routing2)
        
        profile = TimezoneConversion::Profile.new([wtr1, wtr2])
        
        profile.merge_time_ranges!
        profile.time_ranges.size.should == 1
        profile.time_ranges.first.start_min.should == 0
        profile.time_ranges.first.end_min.should == 1439
      end
      
      it "leaves time ranges that have identical routings but that are not adjacent alone" do
        routing1 = TimezoneConversion::Routing.new(50, [1337, 9000])
        routing2 = TimezoneConversion::Routing.new(50, [1337, 9000])
        
        wtr1 = TimezoneConversion::WeeklongTimeRange.new(0, 1200, routing1)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(1202, 1439, routing2)
        
        profile = TimezoneConversion::Profile.new([wtr1, wtr2])
        
        profile.merge_time_ranges!
        profile.time_ranges.size.should == 2
        profile.time_ranges[0].end_min.should == 1200
        profile.time_ranges[1].end_min.should == 1439
      end
      
      it "merges overlapping time ranges" do
        routing1 = TimezoneConversion::Routing.new(50, [1337, 9000])
        routing2 = TimezoneConversion::Routing.new(50, [1337, 9000])
        
        wtr1 = TimezoneConversion::WeeklongTimeRange.new(0, 1200, routing1)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(1200, 1439, routing2)
        
        profile = TimezoneConversion::Profile.new([wtr1, wtr2])
        
        profile.merge_time_ranges!
        profile.time_ranges.size.should == 2
        profile.time_ranges[0].end_min.should == 1200
        profile.time_ranges[1].end_min.should == 1439
      end
      
      it "leaves time ranges with different routings alone" do
        routing1 = TimezoneConversion::Routing.new(50, [1337, 9000])
        routing2 = TimezoneConversion::Routing.new(50, [1337])
        
        wtr1 = TimezoneConversion::WeeklongTimeRange.new(0, 1200, routing1)
        wtr2 = TimezoneConversion::WeeklongTimeRange.new(1201, 1439, routing2)
        
        profile = TimezoneConversion::Profile.new([wtr1, wtr2])
        
        profile.merge_time_ranges!
        profile.time_ranges.size.should == 2
        profile.time_ranges[0].end_min.should == 1200
        profile.time_ranges[1].end_min.should == 1439
      end
      
    end
    
  end
  
end
