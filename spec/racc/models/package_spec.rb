require 'spec_helper'

describe Package do
  before do
    @company = FactoryGirl.create(:company)
    @package = FactoryGirl.create(:package)
  end

  it "should be valid" do
    @package.should be_valid
  end

  it "should require app_id" do
    @package.app_id = nil
    @package.should_not be_valid
    @package.errors.full_messages.join.should match /app can.t be blank/i
  end

  describe 'generate_package_errors' do
    it "should have zero errors associated when each day of a profile set is set to true exactly once" do
      @package.profiles << FactoryGirl.create(:profile, :sun => true)
      @package.profiles << FactoryGirl.create(:profile, :mon => true )
      @package.profiles << FactoryGirl.create(:profile, :tue => true, :wed => true, :thu => true, :fri => true, :sat => true)
      @package.generate_package_errors
      @package.racc_errors.length.should be(0)
    end

    it "should have one error associated with one day duplicated in the profile set" do
      @package.profiles << FactoryGirl.build(:profile, :sun => true, :package => nil)
      @package.profiles << FactoryGirl.build(:profile, :mon => true, :package => nil)
      @package.profiles << FactoryGirl.build(:profile, :name => 'Duplicate Monday', :mon => true, :tue => true,
        :wed => true, :thu => true, :fri => true, :sat => true, :package => nil)

      @package.generate_package_errors
      @package.racc_errors.length.should be(1)
      @package.racc_errors[0].error_message.should == '<b>Monday</b>&nbsp; is set in multiple profiles'
    end

    it "should have one error associated with one day missing in the profile set" do
      @package.profiles << FactoryGirl.create(:profile, :sun => true, :package => nil)
      @package.profiles << FactoryGirl.create(:profile, :mon => true, :package => nil )
      @package.profiles << FactoryGirl.create(:profile, :name => 'Missing Saturday', :tue => true,
        :wed => true, :thu => true, :fri => true, :package => nil)

      @package.generate_package_errors
      @package.racc_errors.length.should be(1)
      @package.racc_errors[0].error_message.should == '<b>Saturday</b>&nbsp; is not set'
    end
  
    it 'will not generate errors for profiles marked for destruction' do
      profile = FactoryGirl.create(:profile, :sun => true, :package => nil)
      profile.stub(:marked_for_destruction?).and_return true
      @package.profiles << profile
    
      @package.generate_package_errors
      @package.racc_errors.should be_empty
    end
  end

  describe "a fully activatable valid package" do
    before(:each) do
      dp = FactoryGirl.create(:destination_property)
      @dest1 = FactoryGirl.create(:destination, :destination => "1111111111", :destination_property_name => dp.destination_property_name)
      @dest2 = FactoryGirl.create(:destination, :destination => "2222222222", :destination_property_name => dp.destination_property_name)
      @dest3 = FactoryGirl.create(:destination, :destination => "3333333333", :destination_property_name => dp.destination_property_name)
      @dest4 = FactoryGirl.create(:destination, :destination => "4444444444", :destination_property_name => dp.destination_property_name)
      @dest5 = FactoryGirl.create(:destination, :destination => "5555555555", :destination_property_name => dp.destination_property_name)
          
      @profile = FactoryGirl.build(:profile, :sun => true, :mon => true,
        :tue => true, :wed => true, :thu => true, :fri => true, :sat => true,
        :package => nil)
      @package.profiles << @profile
    
      time_segment = FactoryGirl.build(:time_segment, :profile => nil)
      @profile.time_segments << time_segment

      routing = FactoryGirl.build(:routing, :percentage => 50, :call_center => 'Chicago', :time_segment => nil)
      time_segment.routings << routing

      routing2 = FactoryGirl.build(:routing, :percentage => 50, :call_center => 'Atlanta', :time_segment => nil)
      time_segment.routings << routing2

      #Create call priorities for routing
      routing.routing_exits <<
        FactoryGirl.build(:destination_exit, :call_priority => 1, :routing => nil, :exit_id => @dest1.id)
      routing.routing_exits <<
        FactoryGirl.build(:destination_exit, :call_priority => 2, :routing => nil, :exit_id => @dest2.id)

      #Create call priorities for routing2
      routing2.routing_exits <<
        FactoryGirl.build(:destination_exit, :call_priority => 1, :routing => nil, :exit_id => @dest1.id)

      routing2.routing_exits <<
        FactoryGirl.build(:destination_exit, :call_priority => 2, :routing => nil, :exit_id => @dest2.id)

      routing2.routing_exits <<
        FactoryGirl.build(:media_exit, :call_priority => 2, :routing => nil,)

      ThreadLocalHelper.stub!(:thread_local_app_id).and_return 1  
    end
    
    context 'for a package with errors' do
      before do
        @package.should_receive(:activation_allowed?).and_return false
      end
      
      it 'will skip route data deletion' do
        DestroyRoute.should_not_receive(:destroy)
        @package.insert_to_racc
      end
      
      it 'will skip insertion if the package has errors' do
        @package.should_not_receive(:insert_to_racc_utc)
        @package.insert_to_racc
      end
    end

    context "helper methods for destroy action" do
      before(:each) do
        @pjson = PackageSerializer.new(@package).as_json
      end

      it "should convert package to serialized format" do
        PackageSerializer.should_receive("new").with(@package)

        @package.serialized
      end

      it "should default to empty array when key does not exist" do
        @package.serialized_ids(:test).should == []
      end

      it "should return array of ids for profiles" do
        ids = @pjson[:profiles].map{|x| x[:id]}

        @package.profile_ids.should == ids
      end

      it "should return array of ids for time_segment_ids" do
        ids = @pjson[:time_segments].map{|x| x[:id]}

        @package.time_segments_ids.should == ids
      end

      it "should return array of ids for routings_ids" do
        ids = @pjson[:routings].map{|x| x[:id]}

        @package.routings_ids.should == ids
      end

      it "should return array of ids for routing_exits_ids" do
        ids = @pjson[:routing_exits].map{|x| x[:id]}

        @package.routing_exits_ids.should == ids
      end
    end
  end
  
  describe "package with building profile" do
    before do
      @profile = FactoryGirl.build(:profile, :sun => true, :mon => true,
        :tue => true, :wed => true, :thu => true, :fri => true, :sat => true,
        :package => nil)
      @package.profiles << @profile
      dp = FactoryGirl.create(:destination_property)
      @dest1 = FactoryGirl.create(:destination, :destination => "1111111111", :destination_property_name => dp.destination_property_name)
    end

    it "should create a deep copy of a @package that is a new @package object" do
      time_segment = FactoryGirl.build(:time_segment, :profile => nil)
      @profile.time_segments << time_segment

      routing = FactoryGirl.build(:routing, :percentage => 50, :call_center => 'Chicago', :time_segment => nil)
      time_segment.routings << routing

      routing2 = FactoryGirl.build(:routing, :percentage => 50, :call_center => 'Atlanta', :time_segment => nil)
      time_segment.routings << routing2

      #Create call prioritys for routing2
      
      routing2.routing_exits <<
        FactoryGirl.build(:destination_exit, :call_priority => 1, :routing => nil, :exit_id => @dest1.id)

      routing2.routing_exits <<
        FactoryGirl.build(:route_exit,
        :call_priority => 2,
        :routing => nil
      )
      routing2.routing_exits <<
        FactoryGirl.build(:media_exit,
        :call_priority => 3,
        :routing => nil
      )
      
      Destination.should_receive(:destination_verified_for_package).with(any_args).any_number_of_times.and_return true

      @new_complete_package = @package.deep_copy

      @new_complete_package.should be_valid
      @new_complete_package.name.should == "Copy of #{@package.name}"
      @new_complete_package.description.should == @package.description
      @new_complete_package.profiles.length.should == 1
      @new_complete_package.profiles[0].time_segments.length.should == 1
      @new_complete_package.profiles[0].time_segments[0].routings.length.should == 2
      @new_complete_package.profiles[0].time_segments[0].routings[1].routing_exits.length.should == 3
    end

    it "should tell me if any time segment for a paticular @package is error free" do
      time_segment = FactoryGirl.build(:time_segment, :profile => nil)
      @profile.time_segments << time_segment
      @package.error_time_segments?.should be(false)
    end

    it "should tell me if any profile for a paticular @package has is error free" do
      @package.error_profiles?.should be(false)
      @package.generate_package_errors
      @package.error_time_segments?.should be_false
    end

    it "should tell me if any profile for a paticular @package has is error free" do
      @package.generate_package_errors
      @package.error_profiles?.should be_false
    end

    it "should tell me if any time segment for a paticular @package has an error" do
      time_segment = FactoryGirl.build(:time_segment, :end_min => 1200, :profile => nil)
      @profile.time_segments << time_segment
      @package.generate_package_errors
      @package.error_time_segments?.should be_true
    end

    it "should tell me if any routing for a paticular routing set has an error" do
      #Create time segment 1
      time_segment = FactoryGirl.build(:time_segment, :profile => nil)
      @profile.time_segments << time_segment

      #Create routing
      routing = FactoryGirl.build(:routing, :percentage => 50, :call_center => 'Chicago', :time_segment => nil)
      time_segment.routings << routing

      routing = FactoryGirl.build(:routing, :percentage => 51, :call_center => 'Atlanta', :time_segment => nil)
      time_segment.routings << routing

      @package.generate_package_errors
      @package.error_routings?.should be_true
    end
  end
  
  it "should create a copy of a @package that is a new @package object" do
    new_package = @package.copy
    new_package.instance_of?(Package).should be(true)
    new_package.new_record?.should == true
    new_package.name.should == "Copy of #{@package.name}"
    new_package.description.should == @package.description
  end

  describe 'error_profiles?' do
    it 'will return false if there are no profile set errors' do
      @package.stub_chain(:racc_errors, :on_profiles, :any?).and_return false
      @package.error_profiles?.should be_false
    end
    
    it 'will return true if the profile set has errors' do
      @package.stub_chain(:racc_errors, :on_profiles, :any?).and_return true
      @package.error_profiles?.should be_true
    end
  end
  
  describe 'error_time_segments?' do
    it 'will return false if there are no time segment set errors' do
      @package.stub_chain(:racc_errors, :on_time_segments, :any?).and_return false
      @package.error_time_segments?.should be_false
    end
    
    it 'will return true if the time_segment set has errors' do
      @package.stub_chain(:racc_errors, :on_time_segments, :any?).and_return true
      @package.error_time_segments?.should be_true
    end
  end

  describe 'error_routings?' do
    it 'will return false if there are no routing set errors' do
      @package.stub_chain(:racc_errors, :on_routings, :any?).and_return false
      @package.error_routings?.should be_false
    end
    
    it 'will return true if the routing set has errors' do
      @package.stub_chain(:racc_errors, :on_routings, :any?).and_return true
      @package.error_routings?.should be_true
    end
  end
  
  describe 'error_routings_exits?' do
    it 'will return false if there are no routing exit set errors' do
      @package.stub_chain(:racc_errors, :on_routing_exits, :any?).and_return false
      @package.error_routing_exits?.should be_false
    end
    
    it 'will return true if the routing exit set has errors' do
      @package.stub_chain(:racc_errors, :on_routing_exits, :any?).and_return true
      @package.error_routing_exits?.should be_true
    end
  end

  it "should tell me when any time segment in any of the @packages profile is empty" do
    #Create phone number
    @group = FactoryGirl.create(:group, :category => 'b')
    @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => "value")

    #Create @package
    @package = FactoryGirl.create(:package, :name => "test name", :description => "test description")
    @vlabel_map.packages << @package

    #Create profile
    @profile = FactoryGirl.create(:profile, :name => "Test", :description => "Test", :sun => true)
    @package.profiles << @profile

    @package.any_empty_time_segment?.should be_true
  end

  it "should tell me when one of the time segments has no routings - empty profiles" do
    #Create phone number
    @group = FactoryGirl.create(:group, :category => 'b')
    @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => "value")

    #Create @package
    @package = FactoryGirl.create(:package, :name => "test name", :description => "test description")
    @vlabel_map.packages << @package    

    @package.any_empty_routing?.should be(true)
  end

  it "should tell me when one of the time segments has no routings -  empty time segments" do
    #Create phone number
    @group = FactoryGirl.create(:group, :category => 'b')
    @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => "value")

    #Create @package
    @package = FactoryGirl.create(:package, :name => "test name", :description => "test description")
    @vlabel_map.packages << @package

    #Create profile
    @profile = FactoryGirl.create(:profile, :name => "Test", :description => "Test", :sun => true)
    @package.profiles << @profile

    @package.any_empty_routing?.should be(true)
  end

  it "should tell me when one of the time segments has no routings - empty routings" do
    #Create phone number
    @group = FactoryGirl.create(:group, :category => 'b')
    @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => "value")


    #Create @package
    @package = FactoryGirl.create(:package, :name => "test name", :description => "test description")
    @vlabel_map.packages << @package

    #Create profile
    @profile = FactoryGirl.create(:profile, :name => "Test", :description => "Test", :sun => false, :mon => true, :tue => true, :wed => true, :thu => true, :fri => true, :sat => true)
    @package.profiles << @profile

    #Create time segment 1
    @time_segment = FactoryGirl.create(:time_segment)
    @profile.time_segments << @time_segment

    @package.any_empty_routing?.should be(true)
  end

  it "should tell me when one of the time segments has no routings - 1 time segment has routings other empty" do
    #Create phone number
    @group = FactoryGirl.create(:group, :category => 'b')
    @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => "value")

    #Create @package
    @package = FactoryGirl.create(:package, :name => "test name", :description => "test description")
    @vlabel_map.packages << @package

    #Create profile
    @profile = FactoryGirl.create(:profile, :name => "Test", :description => "Test", :sun => false, :mon => true, :tue => true, :wed => true, :thu => true, :fri => true, :sat => true)
    @package.profiles << @profile

    #Create time segment 1
    @time_segment = FactoryGirl.create(:time_segment)
    @profile.time_segments << @time_segment

    #Create time segment 2
    @time_segment2 = FactoryGirl.create(:time_segment)
    @profile.time_segments << @time_segment2

    #Create routing 1
    @routing = FactoryGirl.create(:routing, :percentage => 50, :call_center => "Chicago")
    @time_segment.routings << @routing

    #Create routing 2
    @routing = FactoryGirl.create(:routing, :percentage => 50, :call_center => "Atlanta")
    @time_segment.routings << @routing

    @package.any_empty_routing?.should be(true)
  end

  describe "#activate" do
    it "should activate the package" do
      @package.active.should == false
      @package.activate
      @package.active.should == true
    end
    
    it "should de-active all other packages assigned to the phone number" do
      @package.vlabel_map.should_receive(:deactivate_all_packages)
      @package.activate
    end
  
    context "filtering default routes" do
      it "should only filter default routes if it belongs to the default many-to-one group" do
        vlm = @package.vlabel_map
        vlm.group.update_attributes({:category => 'f', :group_default => true})
        @package.should_receive(:add_new_default_route_to_filters).with(vlm)
        @package.activate
      end
      
      it "should not filter default routes if it does not belong to the default many-to-one group" do
        vlm = @package.vlabel_map
        [['f', false], ['b', true]].each do |grp_attr|
          vlm.group.update_attributes({:category => grp_attr[0], :group_default => grp_attr[1]})
          @package.should_not_receive(:add_new_default_route_to_filters).with(vlm)
          @package.activate
        end
      end
    end
  end
  
  describe "add_new_default_route_to_filters" do
    before(:each) do
      @default_grp = FactoryGirl.create(:group, :category => 'f', :group_default => true)
      @new_vlm = FactoryGirl.create(:vlabel_map, :vlabel_group => @default_grp.name)
      @pkg = FactoryGirl.create(:package, :vlabel_map_id => @new_vlm.id)
    end
    
    it "should add the route to all the groups that include new routes" do
      @grp = FactoryGirl.create(:group, :category => 'f', :default_routes_filter => 'N')      
      @pkg.send(:add_new_default_route_to_filters, @new_vlm)
      @grp.default_routes.should == [@new_vlm]
    end
    
    it "should not add the route to groups that do not include new routes" do
      existing_vlm = FactoryGirl.create(:vlabel_map)
      @grp = FactoryGirl.create(:group, :category => 'f', :default_routes_filter => 'L', :default_route_ids => [existing_vlm.id])      
      @pkg.send(:add_new_default_route_to_filters, @new_vlm)
      @grp.default_routes.should == [existing_vlm]
    end
    
    it "should not add the route to groups that include all routes" do
      @grp = FactoryGirl.create(:group, :category => 'f', :default_routes_filter => 'A')      
      @pkg.send(:add_new_default_route_to_filters, @new_vlm)
      @grp.default_routes.should == []
    end
    
    it "should not add the route to default groups" do
      @grp = FactoryGirl.create(:group, :category => 'f', :default_routes_filter => 'N', :group_default => true)      
      @pkg.send(:add_new_default_route_to_filters, @new_vlm)
      @grp.default_routes.should == []
    end
    
    it "should not add the route to one-to-one groups" do
       @grp = FactoryGirl.create(:group, :category => 'b', :default_routes_filter => 'N')   
       @pkg.send(:add_new_default_route_to_filters, @new_vlm)
       @grp.default_routes.should == []
    end
    
    it "should not add to the route to a group not in the current app_id" do
      @grp = FactoryGirl.create(:group, :category => 'f', :default_routes_filter => 'N', :app_id => Time.now.to_i)    
      @pkg.send(:add_new_default_route_to_filters, @new_vlm)
      @grp.default_routes.should == []
    end
  end

  describe "active_package_names_containing" do
    
    before :each do
      @app_id = 1
      group = FactoryGirl.create(:group, :name => 'test_grp_name')
      @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => group.name)
      @p1 = FactoryGirl.create(:package, :active => true, :vlabel_map => @vlabel_map, :name => 'pkg_thing', :app_id => @app_id)
    end
    
    it "should find all active package names for the specified app_id" do
      @p2 = FactoryGirl.create(:package, :active => true, :vlabel_map => @vlabel_map, :name => 'hi_there_hava_a_pkg', :app_id => @app_id)
      
      names = Package.active_package_names_containing('pkg', @app_id)
      names.include?(@p1.name).should == true
      names.include?(@p2.name).should == true
    end
    
    it "should not find packages that do not have a vlabel_map" do
      @p2 = FactoryGirl.create(:package, :active => true, :vlabel_map => nil, :name => 'hi_there_hava_a_pkg', :app_id => @app_id)
      
      names = Package.active_package_names_containing('pkg', @app_id)
      names.include?(@p1.name).should == true
      names.include?(@p2.name).should == false
    end
    
    it "should not find packages that are not active" do
      @p2 = FactoryGirl.create(:package, :active => false, :vlabel_map => @vlabel_map, :name => 'hi_there_hava_a_pkg', :app_id => @app_id)
      
      Package.active_package_names_containing('pkg', @app_id).should == [@p1.name]
    end
  end

  describe "valid_divr_destinations?" do
    context "DIVR destinations" do
      before do
        FactoryGirl.create(:destination_property, :destination_property_name => Destination::DIVR_DESTINATION_PROPERTY)
        @destination = FactoryGirl.create(:destination, :destination_property_name => Destination::DIVR_DESTINATION_PROPERTY, :app_id => 1)
        divr = FactoryGirl.create(:dynamic_ivr)
        @destination.dynamic_ivr = divr
        @vlabel = FactoryGirl.create(:vlabel_map)

        exit = Exit.new({
          type: "Destination",
          value: @destination.destination,
          dequeue_value: ""
        }, @destination.app_id)
        
        @package = @vlabel.packages.new({
          app_id: @destination.app_id,
          active: false,
          direct_route: "yes"
        })
        CreatePackage.create(@package, exit)
      end

      it "returns true if divr destinations have divrs attached" do
        @package.valid_divr_destinations?.should == true
      end

      it "returns false if divr destinations do not have any divrs attached" do
        # Mimic turning off the DIVR in the web
        @destination.dynamic_ivr = nil
        @package.valid_divr_destinations?.should == false        
        #let(:routing_exit)  {FactoryGirl.create(:routing_exit, :exit_id => @destination.id, :exit_type => "Destination")}
        #let(:e) {Exit.new(routing_exit)}
      end
    end
    
    context "non-DIVR destinations" do
      it "returns true if the destination is not a divr destination" do
        FactoryGirl.create(:destination_property, :destination_property_name => "DID_PSTN")
        @destination = FactoryGirl.create(:destination, :destination_property_name => "DID_PSTN", :app_id => 1)
        @vlabel = FactoryGirl.create(:vlabel_map)

        exit = Exit.new({
          type: "Destination",
          value: @destination.destination,
          dequeue_value: ""
        }, @destination.app_id)
        
        package = @vlabel.packages.new({
          app_id: @destination.app_id,
          active: false,
          direct_route: "yes"
        })
        CreatePackage.create(@package, exit)
        package.valid_divr_destinations?.should == true
      end
    end
  end

  describe 'inactive?' do
    it 'should return true if the package is not active' do
      @package.active = false
      @package.inactive?.should be_true
    end
    
    it 'should return false if the package is active' do
      @package.active = true
      @package.inactive?.should be_false
    end
  end
  
  describe :activation_allowed? do
    subject { @package.activation_allowed? }

    context 'without any racc errors' do
      before { @package.stub(:racc_errors).and_return [] }

      it 'returns true if the exits are valid' do
        @package.stub(:exits_valid?).and_return true
        should be_true
      end

      it 'returns false if the exits are invalid' do
        @package.stub(:exits_valid?).and_return false
        should be_false
      end
    end

    context 'with at least one racc error' do
      before { @package.stub(:racc_errors).and_return [RaccError.new] }

      it 'returns false' do
        @package.stub(:exits_valid?).and_return true
        should be_false
      end
    end
  end

  describe :exits_valid? do
    subject { @package.exits_valid? }

    context 'with queuing exits' do
      before { @package.stub(:has_queuing_exits?).and_return true }

      it 'returns true if queuing is active' do
        @package.stub_chain(:company, :queuing_inactive?).and_return false
        should be_true
      end

      it 'returns false if queuing is inactive' do
        @package.stub_chain(:company, :queuing_inactive?).and_return true
        should be_false
      end
    end

    context 'with non-queuing exits' do
      before { @package.stub(:has_queuing_exits?).and_return false }

      it 'returns true' do
        @package.stub_chain(:company, :queuing_inactive?).and_return false
        should be_true
      end
    end
  end

  describe :has_queuing_exits? do
    subject { @package.has_queuing_exits? }

    before do
      @d1 = Destination.new
      @d1.stub(:is_queue?).and_return false
      @d2 = Destination.new
      @d2.stub(:is_queue?).and_return true
      @v1 = VlabelMap.new
    end

    it 'returns false if there are no exits' do
      @package.stub(:exits).and_return []
      should be_false
    end

    it 'returns false if no exits point to a queue' do
      @package.stub(:exits).and_return [@d1, @v1]
      should be_false
    end

    it 'returns true if one or more exits point to a queue' do
      @package.stub(:exits).and_return [@v1, @d1, @d2, @v1]
      should be_true
    end
  end

  describe "activate_active_package" do
    context "return values" do
      before do
        @backend_number = FactoryGirl.build(:vlabel_map)
        @package = FactoryGirl.build(:package)
      end
      
      it "should return true with a success message if the package was activated successfully" do
        @package.should_receive(:valid?).and_return true
        @package.should_receive(:insert_to_racc).and_return true
        
        @package.activate_active_package({}, 'testuser', @backend_number).should == [true, "Package was successfully updated and activated."]
      end

      it "should return false with an error message if the package attributes aren't valid" do
        @package.should_receive(:valid?).and_return false
        @package.errors.add(:base, "This is a fake error")
        
        @package.activate_active_package({}, 'testuser', @backend_number).should == [false, ["This is a fake error"]]
      end
      
      it "should return false with and error message if an error occurred converting the package to a racc route" do
        @package.should_receive(:valid?).and_return true
        @package.should_receive(:insert_to_racc).and_return false
        
        @package.activate_active_package({}, 'testuser', @backend_number).should == [false, "An error occurred while updating this package.  This package was not updated or activated."]
      end      
    end

    context "functionality" do
      before do
        @vlabel = "test_route_a"
        @backend_number = FactoryGirl.create(:vlabel_map, :vlabel => @vlabel)
        @dest = FactoryGirl.create(:destination, :destination => "1112223333")
        exit = Exit.new({
          type: "Destination",
          value: @dest.destination,
          dequeue_value: ""
        }, @dest.app_id)
        
        @package = @backend_number.packages.new({
          app_id: @dest.app_id,
          active: false,
          direct_route: "yes"
        })
        CreatePackage.create(@package, exit)
        @package.set_tz_profiles
        @package.insert_to_racc('testuser')
        @package.activate

        @orig_profile = @package.profiles[0]
        @orig_time_segment = @orig_profile.time_segments[0]
        @orig_routing = @orig_time_segment.routings[0]
        @orig_routing_exit = @orig_routing.routing_exits[0]
        
        @dest_1 = FactoryGirl.create(:destination)
        @dest_2 = FactoryGirl.create(:destination)
        
        @updated_params = {
          "profiles_attributes"=>{
            "0"=>{
              "name"=>"All Days", "app_id"=>"1", "id"=>@orig_profile.id, "_destroy"=>"false",
              "wed"=>"1", "sun"=>"1", "mon"=>"1", "thu"=>"1", "tue"=>"1", "sat"=>"1", "fri"=>"1",
              "time_segments_attributes"=>{
                "1321392900348"=>{
                  "pretty_start"=>"6:00 PM", "pretty_end"=>"11:59 PM",
                  "app_id"=>"1", "_destroy"=>"false", 
                  "routings_attributes"=>{
                    "1321392920418"=>{
                      "app_id"=>"1", "percentage"=>"100", "_destroy"=>"false",
                      "routing_exits_attributes"=>{
                        "1321392924513"=>{
                          "exit_id"=>@dest_1.id, "app_id"=>"1",
                          "exit_type"=>"Destination", "call_priority"=>"1", "_destroy"=>"false"
                        }
                      } 
                    }
                  }
                }, 
                "0"=>{
                  "pretty_start"=>"12:00 AM", "pretty_end"=>"5:59 PM", 
                  "app_id"=>"1", "id"=>@orig_time_segment.id, "_destroy"=>"false",
                  "routings_attributes"=>{
                    "1321392895455"=>{
                      "app_id"=>"1", "percentage"=>"", "_destroy"=>"1"
                    }, 
                    "0"=>{
                      "app_id"=>"1", "id"=>@orig_routing.id, "percentage"=>"100", "_destroy"=>"false",
                      "routing_exits_attributes"=>{
                        "0"=>{
                          "exit_type"=>"Destination", "app_id"=>"1", "exit_id"=> @dest.id, 
                          "id"=>@orig_routing_exit.id, "call_priority"=>"1", "_destroy"=>"false"
                        }, 
                        "1321392932275"=>{
                          "exit_type"=>"Destination", "app_id"=>"1", 
                          "exit_id"=>@dest_2.id, "call_priority"=>"2", "_destroy"=>"false"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }          
      end
      
      it "should create a new racc route with all of changes and keep the package active" do
        @package.activate_active_package(@updated_params, 'testuser', @backend_number)

        profile = @package.profiles[0]
        profile.name.should == "All Days"
        profile.time_segments.map {|ts| [ts.start_min, ts.end_min] }.should =~ [[0, 1079], [1080, 1439]]
        profile.time_segments.where(:start_min => 0).first.routings[0].percentage.should == 100
        profile.time_segments.where(:start_min => 0).first.routings[0].routing_exits.map{ |rd| rd.exit}.should == [@dest, @dest_2]
        profile.time_segments.where(:start_min => 1080).first.routings[0].percentage.should == 100
        profile.time_segments.where(:start_min => 1080).first.routings[0].routing_exits[0].exit.should == @dest_1

        routes = RaccRoute.order(:route_id)
        routes.size.should == 2
        routes[0].route_name.should == @vlabel
        routes[0].day_of_week.should == 254
        routes[0].begin_time.should == 0
        routes[0].end_time.should == 1079
        routes[0].distribution_percentage.should == 100

        routes[1].route_name.should == @vlabel
        routes[1].day_of_week.should == 254
        routes[1].begin_time.should == 1080
        routes[1].end_time.should == 1439
        routes[1].distribution_percentage.should == 100
      end
      
      it "should not save any updates on a package or racc_route if an error occurs" do
        @backend_number.should_receive(:update_modified_time).with('testuser').and_raise StandardError.new("Fake error on updating modified time")
        
        @package.active.should == true
        RaccRoute.where(:route_name => @vlabel).size.should == 1
        bool, msg = @package.activate_active_package(@updated_params, 'testuser', @backend_number)
        bool.should == false
        verify_original_package
        
        RaccRoute.where(:route_name => @vlabel).size.should == 1
      end
      
      it "should not save any updates on a package if there is invalid data" do
        FactoryGirl.create(:destination_property, :destination_property_name => "NETWORK_DIVR")
        invalid_divr_destination = FactoryGirl.create(:destination, :destination => "1231231234", :destination_property_name => "NETWORK_DIVR")
        
        bool, msg = @package.activate_active_package(set_wrong_params(@orig_profile.id, invalid_divr_destination.id), 'testuser', @backend_number)
        bool.should == false
        msg.should == ["Destination is not allowed to be used. #{Destination::DIVR_MESSAGE}"]
        verify_original_package
      end
      
      it "should not save any updates on a package and an error message should be displayed if the destination is invalid" do
        bool, msg = @package.activate_active_package(set_wrong_params(@orig_profile.id,""), 'testuser', @backend_number)
        bool.should == false
        msg.should == ["Exit can't be blank"]
        verify_original_package
      end
      
      def verify_original_package
        @package.active.should == true
        @package.profiles[0].should == @orig_profile
        @package.profiles[0].time_segments[0].should == @orig_time_segment
        @package.profiles[0].time_segments[0].routings[0].should == @orig_routing
        @package.profiles[0].time_segments[0].routings[0].routing_exits[0].should == @orig_routing_exit
      end
      
      def set_wrong_params(orig_prof_id, invalid_dest_id)
        {
          "profiles_attributes"=>{
            "0"=>{
              "name"=>"All Days", "app_id"=>"1", "id"=>@orig_profile.id, "_destroy"=>"false",
              "wed"=>"1", "sun"=>"1", "mon"=>"1", "thu"=>"1", "tue"=>"1", "sat"=>"1", "fri"=>"1",
              "time_segments_attributes"=>{
                "1321392900348"=>{
                  "pretty_start"=>"12:00 AM", "pretty_end"=>"11:59 PM",
                  "app_id"=>"1", "_destroy"=>"false", 
                  "routings_attributes"=>{
                    "1321392920418"=>{
                      "app_id"=>"1", "percentage"=>"100", "_destroy"=>"false",
                      "routing_exits_attributes"=>{
                        "1321392924513"=>{
                          "exit_type"=>"Destination", "app_id"=>"1", 
                          "exit_id"=>invalid_dest_id, "call_priority"=>"1", "_destroy"=>"false"
                        }
                      } 
                    }
                  }
                }
              }
            }
          }
        }
      end
    end
  end
end
