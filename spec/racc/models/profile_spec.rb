require 'spec_helper'

describe Profile do
  before do
    @full_profile = FactoryGirl.build(:profile, :sun => true, :mon => true, :tue => true, 
      :wed => true, :thu => true, :fri => true, :sat => true, :package => nil)
  end

  it "should be valid" do
    @full_profile.should be_valid
  end

  it "should have a valid name" do
    @full_profile.name = ''
    @full_profile.should_not be_valid
    @full_profile.errors.full_messages.to_s.should match /name/i
  end
   
  it "should not save with no days set to true" do
    profile = profile = FactoryGirl.build(:profile, :package => @package)
    profile.should_not be_valid
    profile.errors.full_messages.to_s.should match /at least one day/i
  end
     
  it "should return a listing of days that are being configured" do
    profile =  FactoryGirl.build(:profile, :mon => true, :sat => true )
    profile.active_days.should == ({'mon' => true, 'sat' => true})
  end
  
  it "should return a listing of all days configuration for the week" do
    profile =  FactoryGirl.build(:profile, :mon => true, :sat => true)
    profile.all_days.should == ({'sun' => false, 'mon' => true, 
        'tue' => false, 'wed' => false, 'thu' => false,
        'fri' => false,  'sat' => true})
  end
   
  it "should return a list of all days for a week" do
    profile =  FactoryGirl.build(:profile, :mon => true, :sat => true )
    profile.all_days_ordered_sun_thru_sat.should == [
      #sun , mon , tue  , wed  , thu  , fri  , sat
      false, true, false, false, false, false, true
    ]
  end

  describe :check_time_segment_set_coverage_full_day do
    it "will not generate an error with continous coverage from 0-1439 in a time segment" do
      @full_profile.time_segments.build(start_min: 0, end_min: 1439)
      @full_profile.should_not_receive(:create_time_segment_error)
      @full_profile.check_time_segment_set_coverage_full_day(0, 0)
    end
    
    it "should have one error if the minute 0 is not accounted for" do
      @full_profile.time_segments.build(start_min: 1, end_min: 1439)
      @full_profile.should_receive(:create_time_segment_error).once
      @full_profile.check_time_segment_set_coverage_full_day(0, 0)
    end
    
    it "should have one error associated when there is a gap in the day" do
      @full_profile.time_segments.build(start_min: 0, end_min: 500)
      @full_profile.time_segments.build(start_min: 502, end_min: 1439)
      @full_profile.should_receive(:create_time_segment_error).once
      @full_profile.check_time_segment_set_coverage_full_day(0, 0)
    end
    
    it "should have one error associated with overlapping time segments" do
      @full_profile.time_segments.build(start_min: 0, end_min: 500)
      @full_profile.time_segments.build(start_min: 500, end_min: 1439)
      @full_profile.should_receive(:create_time_segment_error).once
      @full_profile.check_time_segment_set_coverage_full_day(0, 0)
    end

    it 'should generate multiple errors for multiple gaps' do
      @full_profile.time_segments.build(start_min: 0, end_min: 500)
      @full_profile.time_segments.build(start_min: 502, end_min: 1000)
      @full_profile.time_segments.build(start_min: 1002, end_min: 1439)
      @full_profile.should_receive(:create_time_segment_error).twice
      @full_profile.check_time_segment_set_coverage_full_day(0, 0)
    end
  end
  
  it "should convert true booleans of sun, tues, sat to 162" do
    expected_dow = 162
    profile = FactoryGirl.build(:profile)
    profile.sun = true
    profile.tue = true
    profile.sat = true
    dow = profile.create_day_of_week_base10_value
    expected_dow.should == dow
  end
   
  it "should convert true booleans of tues and sat to 34" do
    expected_dow = 34
    profile = FactoryGirl.build(:profile)
    profile.tue = true
    profile.sat = true
    dow = profile.create_day_of_week_base10_value
    expected_dow.should == dow
  end
   
  it "should convert true booleans all weekdays to 124" do
    profile = FactoryGirl.build(:profile)
    profile.mon = true
    profile.tue = true
    profile.wed = true
    profile.thu = true
    profile.fri = true
    profile.sat = false
    profile.sun = false
     
    profile.create_day_of_week_base10_value.should == 124
  end
   
  it "should return false if day_of_year is null" do
    profile = FactoryGirl.build(:profile)
    profile.exception_date?.should be(false)
  end
   
  it "should return true if day_of_year is not null" do
    profile = FactoryGirl.build(:profile)
    profile.day_of_year = Time.now
    profile.exception_date?.should be(true)
  end
   
  it "should copy the profile into a new object" do
    new_profile = @full_profile.copy
     
    new_profile.instance_of?(Profile).should be(true)
    new_profile.new_record?.should == true
    new_profile.name.should == @full_profile.name
    new_profile.description.should == @full_profile.description
    new_profile.wed.should be(true)
  end
   
  describe 'time_segment_attributes=' do
    before do
      @time_segments = stub
      @full_profile.stub(:time_segments) { @time_segments }
    end

    it 'should add a time segment' do
      @time_segments.should_receive(:create).once
      @full_profile.time_segment_attributes = [{:pretty_start => '12:00 AM', :pretty_end => '11:59 PM'}]
    end

    it 'should not add time segments if start time is empty' do
      @time_segments.should_not_receive(:create)
      @full_profile.time_segment_attributes = [{:pretty_start => '', :pretty_end => '11:59 PM'}]
    end

    it 'should not add time segments if start time is nil' do
      @time_segments.should_not_receive(:create)
      @full_profile.time_segment_attributes = [{:pretty_end => '11:59 PM'}]
    end
    
    it 'should not add time segments if end time is empty' do
      @time_segments.should_not_receive(:create)
      @full_profile.time_segment_attributes = [{:pretty_start => '12:00 AM', :pretty_end => ''}]
    end

    it 'should not add time segments if end time is nil' do
      @time_segments.should_not_receive(:create)
      @full_profile.time_segment_attributes = [{:pretty_start => '11:59 PM'}]
    end
  end
end
