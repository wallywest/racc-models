require 'spec_helper'

describe TimeSegment do
  before do
    Company.stub_chain(:find, :max_destinations_for_time_segment) { 50 }
    @time_segment = FactoryGirl.build(:time_segment, :profile => mock_model(Profile))
  end

  it "should be valid" do
    @time_segment.should be_valid
  end

  it "should require app_id" do
    @time_segment.app_id = nil
    @time_segment.should_not be_valid
    @time_segment.errors.full_messages.join.should match /app can.t be blank/i
  end

  it "should not be valid when the begin time is greater than end time" do
    @time_segment.start_min = 50
    @time_segment.end_min = 1
    @time_segment.save.should be(false)
  end
  
  it "should not be valid when a start time is empty" do
    @time_segment.start_min = ""
    @time_segment.end_min = 1
    @time_segment.save.should be(false)
  end
  
  it "should not be valid when the begin time is equal to the end time" do
    @time_segment.start_min = 50
    @time_segment.end_min = 50
    @time_segment.save.should be(false)
  end
    
  it "should provide a begin hour as a two char string < 10 returned " do
    @time_segment.start_min = 70
    @time_segment.start_hour.should == "01"
  end
    
  it "should provide a begin hour as an int > 10 returned " do
    @time_segment.start_min = 660
    @time_segment.start_hour.should == 11
  end
    
  it "should provide a begin min" do
    @time_segment.start_min = 70
    @time_segment.start_minute.should == 10
  end
    
  it "should provide an end hour of a string with two chars < 10" do
    @time_segment.end_min = 70
    @time_segment.end_hour.should == "01"
  end
    
  it "should provide an end hour of an int >= 10" do
    @time_segment.end_min = 600
    @time_segment.end_hour.should == 10
  end
    
  it "should provide an end min " do
    @time_segment.end_min = 70
    @time_segment.end_minute.should == 10
  end
    
  it "should provide an end min as two char string if on the hour " do
    @time_segment.end_min = 60
    @time_segment.end_minute.should == "00"
  end
    
  it "should retun end as 70 for end_hour of 1 and end_minute of 10" do
    @time_segment.end_min = nil
    @time_segment.end_hour=1
    @time_segment.end_minute=10
    @time_segment.end_min.should be(70)
  end
    
  it "should retun start as 70 for end_hour of 1 and end_minute of 10" do
    @time_segment.start_hour=1
    @time_segment.start_minute=10
    @time_segment.start_min.should be(70)
  end
    
  it "should have an end time greater than 0" do
    @time_segment.start_min = 0
    @time_segment.end_min = 0
    @time_segment.save.should be(false)
  end
    
  it "should have an end time less than 1440" do
    @time_segment.start_min = 0
    @time_segment.end_min = 1440
    @time_segment.save.should be(false)
  end
    
  it "should have an end time greater than a begin time" do
    @time_segment.start_min = 900
    @time_segment.end_min = 500
    @time_segment.save.should be(false)
  end
      
  it "should add the total percentages for related routings" do
    @time_segment.routings << FactoryGirl.build(:routing, :percentage => 101)
    @time_segment.routings << FactoryGirl.build(:routing, :percentage => 75)
    @time_segment.routing_percentage_total.should == 176
  end
   
  describe :check_routing_set_percent_is_100 do
    context 'when routing percent total is 100' do
      it 'passes through' do
        @time_segment.stub(:routing_percentage_total) { 100 }
        @time_segment.should_not_receive(:create_routing_set_err)
        @time_segment.check_routing_set_percent_is_100
      end
    end

    context 'when routing percent total is less than 100' do
      it 'creates a routing set error' do
        @time_segment.stub(:routing_percentage_total) { 99 }
        @time_segment.should_receive(:create_routing_set_err)
        @time_segment.check_routing_set_percent_is_100
      end
    end

    context 'when routing percent total is greater than 100' do
      it 'passes through' do
        @time_segment.stub(:routing_percentage_total) { 101 }
        @time_segment.should_receive(:create_routing_set_err)
        @time_segment.check_routing_set_percent_is_100
      end
    end
  end

  it "should go from minutes to pretty " do
    TimeSegment.minutes_to_pretty(100).should == "1:40 AM"
    TimeSegment.minutes_to_pretty(0).should == "12:00 AM"
    TimeSegment.minutes_to_pretty(1439).should == "11:59 PM"
    TimeSegment.minutes_to_pretty(720).should == "12:00 PM"
    TimeSegment.minutes_to_pretty(783).should == "1:03 PM"
  end
    
  it "should go from time to minutes" do
    TimeSegment.time_to_minutes("1:40 AM").should == 100
    TimeSegment.time_to_minutes("12:00 AM").should == 0
    TimeSegment.time_to_minutes("11:59 PM").should == 1439
    TimeSegment.time_to_minutes("12:00 PM").should == 720
    TimeSegment.time_to_minutes("1:03 PM").should == 783
    TimeSegment.time_to_minutes("12:03 AM").should == 3
    TimeSegment.time_to_minutes("12:03 PM").should == 723
    TimeSegment.time_to_minutes("").should == nil
  end
    
  it "should copy a time segment to a new object" do
    new_ts = @time_segment.copy
      
    new_ts.start_min.should == 0
    new_ts.end_min.should == 1439
  end
end
