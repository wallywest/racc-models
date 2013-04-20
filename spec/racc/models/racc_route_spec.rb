require 'spec_helper'

describe RaccRoute do

  before(:each) do
    @racc_route = FactoryGirl.create(:racc_route, :route_id => 2)
    FactoryGirl.create(:destination_property)
  end

  it "should be valid" do
    @racc_route.should be_valid
  end

  describe "#vlabel_map" do
    it "should find the VlabelMap with the same app_id and route_name as the RaccRoute instance" do
      group = FactoryGirl.create(:group, :name => 'F_Testing')
      vlabel_map = FactoryGirl.create(:vlabel_map, :app_id => @racc_route.app_id, :vlabel => @racc_route.route_name)

      @racc_route.vlabel_map.should == vlabel_map

    end
  end

  describe "#add_new_racc_route_destination_xref" do

    before(:each) do
      @racc_route_destination_xref = FactoryGirl.create(:racc_route_destination_xref)
    end

    it "should create a new xref" do
      destination_id = 1
      RaccRouteDestinationXref.should_receive(:create).
      with(:app_id => @racc_route.app_id, :route_id => @racc_route.route_id, :destination_id => destination_id,
      :route_order => @racc_route.racc_route_destination_xrefs.length + 1, :modified_time => anything()).
      and_return(@racc_route_destination_xref)
      @racc_route.add_new_racc_route_destination_xref(destination_id)
    end

    it "should add the xref to the route" do
      destination_id = 1
      RaccRouteDestinationXref.should_receive(:create).
      with(:app_id => @racc_route.app_id, :route_id => @racc_route.route_id, :destination_id => destination_id,
      :route_order => @racc_route.racc_route_destination_xrefs.length + 1, :modified_time => anything()).
      and_return(@racc_route_destination_xref)
      @racc_route.add_new_racc_route_destination_xref(destination_id)
      @racc_route.racc_route_destination_xrefs.length.should == 1
      @racc_route.racc_route_destination_xrefs[0].should == @racc_route_destination_xref
    end
  end

  describe "self#new247route" do
    before do
      @destination = FactoryGirl.create(:destination)
      @exit = Exit.new({
        type: 'Destination',
        value: @destination.destination,
        dequeue_value: 'a_label',
      }, @destination.app_id)
    end

    it 'creates a route with 24/7 100 coverage' do
      route = RaccRoute.new247route('test route', @exit)
      route.route_name.should eq('test route')
      route.day_of_week.should eq(254)
      route.begin_time.should eq(0)
      route.end_time.should eq(1439)
      route.distribution_percentage.should eq(100)
    end

    it 'attaches an xref to the route' do
      route = RaccRoute.new247route('test route', @exit)
      route.racc_route_destination_xrefs.should have(1).item
    end

    it 'associates the specified exit with the route' do
      route = RaccRoute.new247route('test route', @exit)
      xref = route.racc_route_destination_xrefs.first
      xref.exit_type.should eq('Destination')
      xref.destination_id.should eq(@destination.id)
      xref.route_order.should eq(1)
    end

    it 'translates values from the exit onto the xref' do
      route = RaccRoute.new247route('test route', @exit)
      xref = route.racc_route_destination_xrefs.first
      xref.app_id.should eq(@exit.app_id)
      xref.dtype.should eq(@exit.dtype)
      xref.dequeue_label.should eq(@exit.dequeue_value)
      xref.transfer_lookup.should eq(@exit.transfer_lookup)
    end
  end
end
