require 'spec_helper'

describe Routing do
  before do
    @routing = FactoryGirl.build(:routing)
  end

  it "should be valid" do
    @routing.should be_valid
  end

  it "should require app_id" do
    @routing.app_id = nil
    @routing.should_not be_valid
    @routing.errors.full_messages.join.should match /app can.t be blank/i
  end
  
  it "should be a numeric value for percentage" do
    @routing.percentage = 'abc'
    @routing.should_not be_valid
  end
  
  it "should be integer value between 0 and 100 for percentage" do
    @routing.percentage = 105
    @routing.should_not be_valid
  end
  
  it "should allow 0 for percentage" do
   @routing.percentage = 0
   @routing.should be_valid
  end
  
  it "should copy self to a new routing object" do
    @routing.percentage = 50

    new_routing = @routing.copy
    
    new_routing.instance_of?(Routing).should be(true)
    new_routing.percentage.should == 50
  end 
  
  it "should prioritize the destinations" do
    @routing.routing_exits << FactoryGirl.build(:routing_exit,
      :exit_id=> 1, :call_priority => 1, :exit_type => "Destination")
    @routing.routing_exits << FactoryGirl.build(:routing_exit,
      :exit_id=> 2, :call_priority => 3, :exit_type => "Destination")

    @routing.prioritize_exits
    @routing.routing_exits[1].call_priority.should == 2
  end
  
  describe 'check_routing_exits_are_valid' do
    before do
      @dest1, @dest2, @dest3 = [Destination.new, Destination.new, VlabelMap.new]
      @dest1.stub(:routable?).and_return true
      @dest2.stub(:routable?).and_return false
    end
    
    it 'generates an error for each invalid exit' do
      @routing.stub_chain(:routing_exits, :map).and_return [@dest1, @dest2, @dest2, @dest3]
      @routing.should_receive(:generate_error).once
      @routing.check_routing_exits_are_valid
    end
    
    it 'passes through if all exits are valid' do
      @routing.stub_chain(:routing_exits, :map).and_return [@dest1, @dest3]
      @routing.should_not_receive(:generate_error)
      @routing.check_routing_exits_are_valid
    end
  end
end
