require 'spec_helper'

describe PrerouteGroup do
  describe "validation" do
    subject { FactoryGirl.build(:preroute_group) }

    it { should be_valid }

    it 'requires an app_id' do
      subject.app_id = nil
      subject.should_not be_valid
    end

    it 'requires a group name' do
      subject.group_name = nil
      subject.should_not be_valid
    end

    it 'requires the preroute_enabled flag' do
      subject.preroute_enabled = nil
      subject.should_not be_valid
    end

    it 'requires a group name less than 65 chars' do
      subject.group_name = 'a' * 65
      subject.should_not be_valid
    end
  end
  
  describe :destroy_route do
    it 'invokes the DestroyRoute action' do
      preroute = FactoryGirl.build(:preroute_group)
      DestroyRoute.should_receive(:destroy).with(preroute.route_name, preroute.app_id)
      preroute.send(:destroy_route)
    end
  end

  describe :enabled do
    it 'returns enabled preroute groups' do
      pr1 = FactoryGirl.create(:preroute_group, :preroute_enabled => 'F')
      pr2 = FactoryGirl.create(:preroute_group, :preroute_enabled => 'T')
      PrerouteGroup.enabled.should == [pr2]
    end
    
    it 'returns empty array if there are no preroutes' do
      PrerouteGroup.enabled.should == []
    end
  end

  describe :generate_route_name do
    it 'generates a name based on the current time' do
      new_time = Time.local(2008, 9, 1, 12, 0, 0)

      Timecop.freeze(new_time)

      name = (Time.now.to_f * 1000).to_i
      
      preroute = PrerouteGroup.new
      preroute.send(:generate_route_name)
      preroute.route_name.should eq("preroute[#{name}]")

      Timecop.return
    end
  end
  
  describe :with_exits do
    before do
      @destination = FactoryGirl.create(:destination)
      @preroute = FactoryGirl.create(:preroute_group)
      @route = FactoryGirl.create(:racc_route, route_name: @preroute.route_name)
      @route_xref = FactoryGirl.create(:racc_route_destination_xref,
        racc_route: @route, exit: @destination)
    end

    it 'returns preroute groups with their exits' do
      preroutes = PrerouteGroup.with_exits(@preroute.app_id)
      preroutes.first.exit_value.should eq(@destination.destination)
      preroutes.first.exit_type.should eq('Destination')
    end
  end
end
