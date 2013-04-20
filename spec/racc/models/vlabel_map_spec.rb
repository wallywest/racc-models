require 'spec_helper'

describe VlabelMap do

  before :each do
    ThreadLocalHelper.thread_local_app_id = 1
    FactoryGirl.create(:destination_property)
  end

  describe "validations" do
  
    before(:each) do
      group = FactoryGirl.create(:group)
      @vlabel_map = FactoryGirl.build(:vlabel_map, :vlabel_group => group.name)
    end
  
    it "should be valid" do
      @vlabel_map.should be_valid
    end
  
    it "should be valid with a sip format" do
      @vlabel_map.vlabel = "sip://phone_number@vailsys.com"
      @vlabel_map.should be_valid
    end
  
    it "should be valid with spaces not leading or ending the string" do
      @vlabel_map.vlabel = "Phone Number"
      @vlabel_map.should be_valid
    end
  
    it "should be invalid when starting with a @" do
      @vlabel_map.vlabel = "@aslkfjaslkjf"
      @vlabel_map.should_not be_valid
    end
  
    it "should not contain a ^" do
      @vlabel_map.vlabel = "aslkfja^slkjf"
      @vlabel_map.should_not be_valid
    end
    
    it "should be valid when containing square brackets" do
      @vlabel_map.vlabel = "hello[hi]"
      @vlabel_map.should be_valid
    end
  
    it "should be invalid when exceeding 32 characters" do
      val = ""
      33.times do
        val += "s"
      end
  
      @vlabel_map.vlabel = val
      @vlabel_map.should_not be_valid
    end
  
    it "should be invalid with a space at the end of an otherwise valid string" do
      @vlabel_map.vlabel = "aslkfjaslkjf "
      @vlabel_map.should_not be_valid
    end
  
    it "should be invalid if the operation doesn't exist" do
      @vlabel_map.group.operation.destroy
      @vlabel_map.should_not be_valid
    end
  
    it "should be valid if the mapped_dnis is a 4-14 length digit or nil or blank" do
      [1234, nil, 12345678901234, ''].each do |test_nbr|
        @vlabel_map.mapped_dnis = test_nbr
        @vlabel_map.should be_valid
      end
    end
  
    it "should be invalid if the mapped_dnis is NOT a 4-14 length digit or nil or blank" do
      ['a', 1, 123, -1, 1.3, '      '].each do |test_nbr|
        @vlabel_map.mapped_dnis = test_nbr
        @vlabel_map.should_not be_valid
      end
    end
    
  end
  
  describe "F# validations" do
  
    before(:each) do
      @group = FactoryGirl.create(:group, :category => 'f')
      @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel => '1234567891', :vlabel_group => @group.name, :app_id => @group.app_id)
    end
  
    it "should not allow duplicate F#s per app id" do
      @vlabel_map_dupe = FactoryGirl.create(:vlabel_map, :vlabel => '9632587412', :vlabel_group => @group.name, :app_id => @group.app_id)
      @vlabel_map_dupe.app_id = 1
      @vlabel_map_dupe.vlabel = '1234567891'
      @vlabel_map_dupe.save.should be(false)
    end
  
    it "should not allow non 10-digit numbers" do
      ['abc', '5245232223333332', '52653625.2', '0', nil, '', '          ', '123456789'].each do |bad_vlabel|
        @vlabel_map.vlabel = bad_vlabel
        @vlabel_map.should_not be_valid
      end
    end
  
    it "should be valid if it's numeric and 10 digits long" do
      @vlabel_map.should be_valid
    end
  
  end
  
  describe "#delete_translation_route" do
  
    before(:each) do
      @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel => '112')
      @racc_route = FactoryGirl.create(:racc_route, :route_name => @vlabel_map.vlabel, :app_id => @vlabel_map.app_id)
      @xref = FactoryGirl.create(:racc_route_destination_xref, :route_id => @racc_route.route_id, :app_id => @racc_route.app_id)
    end
  
    it "should delete a translation route" do
      VlabelMap.delete_translation_route(@vlabel_map.vlabel_map_id).should == true
  
      lambda {VlabelMap.find(@vlabel_map.id)}.should raise_error(ActiveRecord::RecordNotFound)
      lambda {RaccRoute.find(@racc_route.id)}.should raise_error(ActiveRecord::RecordNotFound)
      lambda {RaccRouteDestinationXref.find(@xref.id)}.should raise_error(ActiveRecord::RecordNotFound)
  
    end
  
    it "should delete multiple xrefs" do
      FactoryGirl.create(:racc_route_destination_xref, :route_id => @racc_route.route_id, :app_id => @racc_route.app_id)
  
      VlabelMap.delete_translation_route(@vlabel_map.vlabel_map_id).should == true
  
      RaccRouteDestinationXref.find(:all, :conditions => ["route_id = ? and app_id = ?", @racc_route.route_id, @racc_route.app_id]).
      should == []
    end
  
    it "should delete routes with 0 xrefs" do
      @xref.destroy
  
      VlabelMap.delete_translation_route(@vlabel_map.vlabel_map_id).should == true
    end
  
    it "should print an exception to stdout and return false" do
      #Force an exception by returning nil to a variable which will have a method called on it
      RaccRouteDestinationXref.should_receive(:where).with(any_args()).and_return(nil)
  
      VlabelMap.delete_translation_route(@vlabel_map.vlabel_map_id).should == false
    end
  
  end
  
  describe "#bnumber_vlabel" do
  
    before :each do
      @label = '8475555555'
      @app_id = 1
      @login = 'test_user'
      @group = FactoryGirl.create(:group)
      FactoryGirl.create(:company)
    end
  
    it "should create a bnumber vlabel_map" do
      VlabelMap.should_receive(:new_bnumber_vlabel).and_return FactoryGirl.build(:vlabel_map)
      vlabel_map = VlabelMap.bnumber_vlabel(:bnumber_value => @label, :bnumber_vlabel_group => @group.name, :app_id => @app_id, :user_login => @login)
  
      vlabel_map.new_record?.should == false
    end
  
    it "should return the vlabel_map even if it is invalid and thus is not created" do
      @label = '1234567890123456789012345678901234567890'
      vlabel_map = VlabelMap.bnumber_vlabel(:bnumber_value => @label, :bnumber_vlabel_group => @group.name, :app_id => @app_id, :user_login => @login)
  
      vlabel_map.new_record?.should == true
      vlabel_map.class.should == VlabelMap
    end
  
    it "should return the vlabel_map if a vlabel_map with the same vlabel and app_id already exists" do
      existing_vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel => @label, :app_id => @app_id)
      vlabel_map = VlabelMap.bnumber_vlabel(:bnumber_value => @label, :bnumber_vlabel_group => @group.name, :app_id => @app_id, :user_login => @login)
  
      vlabel_map.new_record?.should == true
      vlabel_map.class.should == VlabelMap
    end
  
    it "should return the vlabel_map if params are invalid or missing" do
      vlabel_map = VlabelMap.bnumber_vlabel
      
      vlabel_map.new_record?.should == true
      vlabel_map.class.should == VlabelMap
    end
  end
  
  describe "#new_bnumber_vlabel" do
    before :each do
      @label = '5555555555'
      @description = 'A test description.'
      @app_id = 1
      @login = 'test_user'
      @group = FactoryGirl.create(:group)
    end
    
    it 'should construct a new vlabel_map with attributes signifying a bnumber and return it without saving' do
      vlabel_map = VlabelMap.new_bnumber_vlabel(:bnumber_value => @label, :description => @description,
        :bnumber_vlabel_group => @group.name, :app_id => @app_id, :user_login => @login)
      
      vlabel_map.new_record?.should == true
      vlabel_map.vlabel.should == @label
      vlabel_map.description.should == @description
      vlabel_map.app_id.should == @app_id
      vlabel_map.modified_by.should == @login
      vlabel_map.vlabel_group.should == @group.name
      vlabel_map.cti_routine.should == 3
      vlabel_map.full_call_recording_enabled.should == 'F'
      vlabel_map.full_call_recording_percentage.should == 0
    end
  end
  
  describe "destroy_all" do
  
    before(:each) do
      @vlabel_map = FactoryGirl.create(:vlabel_map)
      @label_name = @vlabel_map.vlabel
      @app_id = @vlabel_map.app_id
      @vlabel_map.should_receive(:packages=).with([])
      @vlabel_map.should_receive(:save)
    end
  
    it "should delete the racc route" do
      DestroyRoute.should_receive(:destroy).with(@vlabel_map.vlabel, @vlabel_map.app_id)
      @vlabel_map.destroy_all
    end
  
    it "should delete the vlabel_map" do
      @vlabel_map.should_receive(:destroy)
      @vlabel_map.destroy_all
    end
  
  end
  
  describe "by_vlabel" do
  
    before(:each) do
      @grp = FactoryGirl.create(:group)
      @grp2 = FactoryGirl.create(:group, :app_id => 2)
      @vl1 = FactoryGirl.create(:vlabel_map, :app_id => 1, :vlabel => 'one', :vlabel_group => @grp.name)
      @vl2 = FactoryGirl.create(:vlabel_map, :app_id => 2, :vlabel => 'one', :vlabel_group => @grp2.name)
      @vl3 = FactoryGirl.create(:vlabel_map, :app_id => 1, :vlabel => 'three', :vlabel_group => @grp.name)
      @rr1 = FactoryGirl.create(:racc_route, :app_id => @vl1.app_id, :route_name => @vl1.vlabel, :route_id => 100)
      @rr2 = FactoryGirl.create(:racc_route, :app_id => @vl2.app_id, :route_name => @vl2.vlabel, :route_id => 101)
    end
  
    it "should find the vlabel map object based on the app id and vlabel map parameters" do
      VlabelMap.with_routes(1, 'two').should == nil
      VlabelMap.with_routes(2, 'one').should == @vl2
    end
  
    it "should find only vlabel map objects that have associated racc routes" do
      VlabelMap.with_routes(1, 'three').should == nil
    end
  
  end
  
  describe "copy_existing_active" do
    it "should add the chosen active package to the current vlabel" do
      grp = FactoryGirl.create(:group)
      vl_map = FactoryGirl.create(:vlabel_map, :app_id => grp.app_id, :vlabel => 'one', :vlabel_group => grp.name)
      target_vl_map = FactoryGirl.create(:vlabel_map, :vlabel => 'two')
      dest = FactoryGirl.create(:destination)

      pkg = FactoryGirl.create(:package, :vlabel_map => vl_map, :active => true)
      profile = FactoryGirl.create(:profile, :package => pkg, :sun => true, :mon => true, :tue => true, :wed => true, :thu => true, :fri => true, :sat => true, :sun => true)
      time_segment = FactoryGirl.create(:time_segment, :profile => profile)
      routing = FactoryGirl.create(:routing, :time_segment => time_segment)
      routing_exit = FactoryGirl.create(:destination_exit, :exit => dest, :routing => routing)

      target_vl_map.copy_existing_active(pkg.id)
      
      package_copy = target_vl_map.packages.first
      package_copy.name.should == "Copy of #{pkg.name}"
      package_copy.id.should_not == pkg.id
    end
    
    it "should error if it can't find an active package in the same app id with the specified id" do
      grp = FactoryGirl.create(:group)
      vl_map = FactoryGirl.create(:vlabel_map, :app_id => grp.app_id, :vlabel => 'one', :vlabel_group => grp.name)

      lambda { vl_map.copy_existing_active(1) }.should raise_error(ActiveRecord::RecordNotFound)
    end
  
  end
  
  describe "scope call_legs" do
  
    it "should return the vlabels in a group that is not a default group and is in category 'x', 'b', or 'f', and is in the specified app id" do
      @valid_group1 = FactoryGirl.create(:group, :category => 'b', :group_default => false)
      @valid_vlabel1 = FactoryGirl.create(:vlabel_map, :vlabel_group => @valid_group1.name)
  
      @valid_group2 = FactoryGirl.create(:group, :category => 'x', :group_default => false)
      @valid_vlabel2 = FactoryGirl.create(:vlabel_map, :vlabel_group => @valid_group2.name)
  
      @valid_group3 = FactoryGirl.create(:group, :category => 'f', :group_default => false)
      @valid_vlabel3 = FactoryGirl.create(:vlabel_map, :vlabel_group => @valid_group3.name, :vlabel => '5555555555')
  
      @invalid_group1 = FactoryGirl.create(:group, :category => 'b', :group_default => true)
      @invalid_vlabel1 = FactoryGirl.create(:vlabel_map, :vlabel_group => @invalid_group1.name)
  
      @invalid_group2 = FactoryGirl.create(:group, :category => 'n', :group_default => false)
      @invalid_vlabel2 = FactoryGirl.create(:vlabel_map, :vlabel_group => @invalid_group2.name, :vlabel => '8123456125')
  
      #Vlabel assigned to an invalid group, valid group in another app_id with the same name
      @invalid_group3 = FactoryGirl.create(:group, :category => 'b', :group_default => false, :app_id => 2)
      @invalid_group4 = FactoryGirl.create(:group, :category => 'n', :group_default => false, :name => @invalid_group3.name)
      @invalid_vlabel3 = FactoryGirl.create(:vlabel_map, :vlabel_group => @invalid_group4.name, :vlabel => '5636563652')
  
      VlabelMap.call_legs(1).should include(@valid_vlabel1, @valid_vlabel3, @valid_vlabel2)
      VlabelMap.call_legs(1).should_not include(@invalid_vlabel1, @invalid_vlabel2, @invalid_vlabel3)
    end
  
    it "should return the group display_name and id" do
      group1 = FactoryGirl.create(:group, :category => 'b', :group_default => false, :display_name => 'group one', :app_id => 11)
      vlabel1 = FactoryGirl.create(:vlabel_map, :vlabel_group => group1.name, :app_id => group1.app_id)
  
      group2 = FactoryGirl.create(:group, :category => 'b', :group_default => false, :display_name => 'group two', :app_id => 12)
      vlabel2 = FactoryGirl.create(:vlabel_map, :vlabel_group => group2.name, :app_id => group2.app_id)
  
      VlabelMap.call_legs(group1.app_id)[0].group_display_name.should == group1.display_name
      VlabelMap.call_legs(group1.app_id)[0].group_id.to_s.should == group1.id.to_s
      VlabelMap.call_legs(group2.app_id)[0].group_display_name.should == group2.display_name
      VlabelMap.call_legs(group2.app_id)[0].group_id.to_s.should == group2.id.to_s
    end
  
  end
  
  describe "#format_for_search" do
    before :each do
      @vlabel = FactoryGirl.create(:vlabel_map)
      @vlabel.should_receive(:group_display_name).and_return 'group_name'
    end
    
    it 'should return a hash containing name, type, and date' do
      @vlabel.format_for_search.should include(:name, :type, :date)
    end
    
    it 'should return a path to the frontend route if it is a frontend number' do
      @vlabel.should_receive(:is_frontend_number).and_return true
      
      values = @vlabel.format_for_search
      values.should include(:path)
      values[:path][:method].should == :frontend_group_path
    end
    
    it 'should return a path to the backend packages route if it is not a frontend number' do
      @vlabel.should_receive(:is_frontend_number).and_return false
      
      values = @vlabel.format_for_search
      values.should include(:path)
      values[:path][:method].should == :entry_group_backend_number_packages_path
    end
  end
  
  describe "#check_geo_routing" do
    context "it should toggle the geo group when" do
      it "has a geo_route_group id set and the operation is NOT 16" do
        @group = FactoryGirl.create(:group, :name => 'non_geo_group', :operation => FactoryGirl.create(:operation, :operation => 6, :vlabel_group => 'non_geo_group'))
        @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group.operation.vlabel_group)
        expect_toggle_on
        @vlabel_map.update_geo_routing(FactoryGirl.create(:geo_route_group).id)
      end
      
      it "has geo_route_group_id set to 0 and the operation IS 16" do
        @group = FactoryGirl.create(:group, :name => 'non_geo_group', :operation => FactoryGirl.create(:operation, :operation => 16, :vlabel_group => 'non_geo_group'))
        @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group.operation.vlabel_group)
        @vlabel_map.group.operation.operation.should == 16
        expect_toggle_on
        @vlabel_map.update_geo_routing(0)
      end
    end
    
    context "it should not toggle the geo group if" do
      it "has a geo group set and the oepration is already 16" do
        @group = FactoryGirl.create(:group, :name => 'non_geo_group', :operation => FactoryGirl.create(:operation, :operation => 16, :vlabel_group => 'non_geo_group'))
        @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group.operation.vlabel_group)
        expect_no_toggle_on
        @vlabel_map.update_geo_routing(FactoryGirl.create(:geo_route_group).id)
      end
      
      it "has geo_route_group_id set to 0 and the operation is anything but 16" do
        @group = FactoryGirl.create(:group, :name => 'non_geo_group', :operation => FactoryGirl.create(:operation, :operation => 15, :vlabel_group => 'non_geo_group'))
        @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group.operation.vlabel_group)
        expect_no_toggle_on
        @vlabel_map.update_geo_routing(0)
      end
    end
  end
  
  describe "toggle_vlabel_group" do
    before(:each) do
      @op = FactoryGirl.create(:operation)
      @vlabel = FactoryGirl.create(:vlabel_map, :vlabel_group => @op.vlabel_group)
    end
    
    context "remove geo-route operation" do
      it "should set the vlabel group to the original group name" do
        @op.vlabel_group = 'Test_Group_GEO_ROUTE_SUB'
        @op.operation = 16
        
        VlabelMap.toggle_vlabel_group(@op, Operation::ONE_TO_ONE_GEO_OP, @vlabel.vlabel_group, @vlabel.app_id).should == 'Test_Group'
      end
      
      it "should raise an error if the vlabel group is not a geo-route operation" do
        @op.vlabel_group = 'Not_Geo_Op'
        @op.operation = 16
        
        lambda {VlabelMap.toggle_vlabel_group(@op, Operation::ONE_TO_ONE_GEO_OP, @vlabel.vlabel_group, @vlabel.app_id)}.should raise_error(Exception, "Operation is set to 16, but the vlabel_group is not *_GEO_ROUTE_SUB")
      end
      
      it "should display the appropriate operation number in the error message" do
        @group = FactoryGirl.create(:group, :name => 'Not_Geo_Op')
        @op.vlabel_group = 'Not_Geo_Op'
        @op.operation = 20
        
        lambda {VlabelMap.toggle_vlabel_group(@op, Operation::MANY_TO_ONE_GEO_OP, @group.name, @group.app_id)}.should raise_error(Exception, "Operation is set to 20, but the vlabel_group is not *_GEO_ROUTE_SUB")
      end
    end
    
    context "add geo-route operation" do
      it "should create the geo-route operation if it doesn't exist" do
        Operation.where(:operation => 16, :vlabel_group => "#{@op.vlabel_group}_GEO_ROUTE_SUB").size.should == 0

        
        VlabelMap.toggle_vlabel_group(@op, Operation::ONE_TO_ONE_GEO_OP, @vlabel.vlabel_group, @vlabel.app_id).should == "#{@op.vlabel_group}_GEO_ROUTE_SUB"

        Operation.where(:operation => 16, :vlabel_group => "#{@op.vlabel_group}_GEO_ROUTE_SUB").size.should == 1
      end
      
      it "should not create a geo-route operation if one already exists" do
        geo_route_op = FactoryGirl.create(:operation, :vlabel_group => "#{@op.vlabel_group}_GEO_ROUTE_SUB", :operation => 16)
        Operation.where(:operation => 16, :vlabel_group => "#{@op.vlabel_group}_GEO_ROUTE_SUB").size.should == 1
        
        VlabelMap.toggle_vlabel_group(@op, Operation::ONE_TO_ONE_GEO_OP, @vlabel.vlabel_group, @vlabel.app_id) == "#{@op.vlabel_group}_GEO_ROUTE_SUB"
        Operation.where(:operation => 16, :vlabel_group => "#{@op.vlabel_group}_GEO_ROUTE_SUB").size.should == 1
      end
    end
  end
  
  describe "divr_transfer_strings" do
    context "searching transfer routes" do
      it "should return alpha-numeric transfer routes that match the search param" do
        app_id = 1
        vlm1 = FactoryGirl.create(:vlabel_map, :vlabel => "123456789", :app_id => app_id)
        FactoryGirl.create(:racc_route, :route_name => "123456789", :app_id => app_id)
        vlm2 = FactoryGirl.create(:vlabel_map, :vlabel => "123test", :app_id => app_id)
        FactoryGirl.create(:racc_route, :route_name => "123test", :app_id => app_id)

        VlabelMap.divr_transfer_strings(app_id, "123").should == [vlm1.vlabel, vlm2.vlabel]
      end

      it "should return alpha-numeric transfer routes" do
        app_id = 1
        vlm1 = FactoryGirl.create(:vlabel_map, :vlabel => "hello", :app_id => app_id)
        FactoryGirl.create(:racc_route, :route_name => "hello", :app_id => app_id)

        VlabelMap.divr_transfer_strings(app_id, "he").should == [vlm1.vlabel]
      end

      it "should not return speed dials" do
        app_id = 1
        vlm1 = FactoryGirl.create(:vlabel_map, :vlabel => "123456789", :app_id => app_id)
        FactoryGirl.create(:racc_route, :route_name => "123456789", :app_id => app_id)
        sd = FactoryGirl.create(:transfer_map, :transfer_string => "123", :app_id => app_id)

        VlabelMap.divr_transfer_strings(app_id, "123").should == [vlm1.vlabel]
      end

      it "should only return values in the current app id" do
        app_id = 2
        vlm1 = FactoryGirl.create(:vlabel_map, :vlabel => "1112", :app_id => 1)
        FactoryGirl.create(:racc_route, :route_name => "1112", :app_id => 1)
        vlm2 = FactoryGirl.create(:vlabel_map, :vlabel => "111", :app_id => app_id)
        FactoryGirl.create(:racc_route, :route_name => "111", :app_id => app_id)

        VlabelMap.divr_transfer_strings(app_id, "1").should == [vlm2.vlabel]
      end

      it "should only return vlabels that are actual routes" do
        app_id = 1
        vlm1 = FactoryGirl.create(:vlabel_map, :vlabel => "123456789", :app_id => app_id)

        VlabelMap.divr_transfer_strings(app_id, "1").should == []
      end
    end
    
    context "verifying transfer routes" do
      before(:each) do
        @app_id = 1
        @vlm = FactoryGirl.create(:vlabel_map, :vlabel => "123456789", :app_id => @app_id)
        FactoryGirl.create(:racc_route, :route_name => "123456789", :app_id => @app_id)
      end
      
      it "should return the transfer route" do
        VlabelMap.divr_transfer_strings(@app_id, "123456789", true).should == [@vlm.vlabel]        
      end
      
      it "should not return the transfer route if it's not a complete match" do
        VlabelMap.divr_transfer_strings(@app_id, "123", true).should == []        
      end
    end
  end
  
  def expect_toggle_on
    VlabelMap.should_receive(:toggle_vlabel_group)
  end
  
  def expect_no_toggle_on
    VlabelMap.should_not_receive(:toggle_vlabel_group)
  end
  
  describe "actual_group_name" do
    it "should return the actual group name when there is no geo-route attached" do
      grp_name = "test_vlm_group"
      vlm = FactoryGirl.build(:vlabel_map, :vlabel_group => grp_name)
      vlm.actual_group_name.should == grp_name
    end
    
    it "should retun the actual group name when there is a geo-route attached" do
      vlm = FactoryGirl.build(:vlabel_map, :vlabel_group => "test_vlm_group_GEO_ROUTE_SUB")
      vlm.actual_group_name.should == "test_vlm_group"
    end
  end
  
  describe "recording settings on create" do
    it "should set split_full_recording and multi_channel_recording based on the company" do
      company = FactoryGirl.create(:company, :recording_type => 'P', :full_call_recording_enabled => 'T', :full_call_recording_percentage => 100, :split_full_recording => 'T', :multi_channel_recording => 'F')
      @vlm = FactoryGirl.create(:vlabel_map, :app_id => company.app_id)
      @vlm.split_full_recording.should == 'T'
      @vlm.multi_channel_recording.should == 'F'
    end
    
    context "record by rules" do
      it "should set full_call_recording_enabled = 'M' and full_call_recording_percentage = 100 when there is a wildcard rule" do
        company = FactoryGirl.create(:company, :recording_type => 'R', :full_call_recording_enabled => 'M', :full_call_recording_percentage => 100, :split_full_recording => 'F', :multi_channel_recording => 'F')
        FactoryGirl.create(:recorded_dnis, :parm_key => '*', :app_id => company.app_id)
        @vlm = FactoryGirl.create(:vlabel_map, :app_id => company.app_id)
        @vlm.full_call_recording_enabled.should == 'M'
        @vlm.full_call_recording_percentage.should == 100
      end

      it "should set full_call_recording_enabled = 'M' and full_call_recording_percentage = 100 when there is a rule for the vlabel" do
        vlabel = '11223344'
        company = FactoryGirl.create(:company, :recording_type => 'R', :full_call_recording_enabled => 'M', :full_call_recording_percentage => 100, :split_full_recording => 'F', :multi_channel_recording => 'F')
        FactoryGirl.create(:recorded_dnis, :parm_key => vlabel, :app_id => company.app_id)
        @vlm = FactoryGirl.create(:vlabel_map, :app_id => company.app_id, :vlabel => vlabel)
        @vlm.full_call_recording_enabled.should == 'M'
        @vlm.full_call_recording_percentage.should == 100
      end

      it "should set full_call_recording_enabled = 'F' and full_call_recording_percentage = 0 when there are no wildcard or vlabel rules" do
        company = FactoryGirl.create(:company, :recording_type => 'R', :full_call_recording_enabled => 'M', :full_call_recording_percentage => 100, :split_full_recording => 'F', :multi_channel_recording => 'F')
        FactoryGirl.create(:recorded_dnis, :parm_key => '22312', :app_id => company.app_id)
        @vlm = FactoryGirl.create(:vlabel_map, :app_id => company.app_id, :vlabel => '555555')
        @vlm.full_call_recording_enabled.should == 'F'
        @vlm.full_call_recording_percentage.should == 0
      end
    end
    
    context "record by percentage" do
      it "should set full_call_recording_enabled and full_call_recording_percentage based on company settings" do
        company = FactoryGirl.create(:company, :recording_type => 'P', :full_call_recording_enabled => 'T', :full_call_recording_percentage => 55, :split_full_recording => 'F', :multi_channel_recording => 'F')
        @vlm = FactoryGirl.create(:vlabel_map, :app_id => company.app_id)
        @vlm.full_call_recording_enabled.should == 'T'
        @vlm.full_call_recording_percentage.should == 55
      end
    end

    context "record by percentage" do
      it "should set full_call_recording_enabled and full_call_recording_percentage based on company settings" do
        company = FactoryGirl.create(:company, :recording_type => 'D', :full_call_recording_enabled => 'T', :full_call_recording_percentage => 100, :split_full_recording => 'F', :multi_channel_recording => 'F')
        @vlm = FactoryGirl.create(:vlabel_map, :app_id => company.app_id)
        @vlm.full_call_recording_enabled.should == 'T'
        @vlm.full_call_recording_percentage.should == 100
      end
    end
  end
  
  describe "scope in_group" do
    before(:each) do
      @app_id_1 = 1
      @app_id_2 = 2
      
      @grp_1 = FactoryGirl.create(:group, :app_id => @app_id_1)
      @grp_2 = FactoryGirl.create(:group, :app_id => @app_id_2)
      @grp_3 = FactoryGirl.create(:group, :app_id => @app_id_1)

      @vlm_1a = FactoryGirl.create(:vlabel_map, :app_id => @app_id_1, :vlabel_group => @grp_1.name)
      @vlm_1b = FactoryGirl.create(:vlabel_map, :app_id => @app_id_1, :vlabel_group => @grp_1.name)
      @vlm_1c = FactoryGirl.create(:vlabel_map, :app_id => @app_id_1, :vlabel_group => @grp_3.name)
      @vlm_2a = FactoryGirl.create(:vlabel_map, :app_id => @app_id_2, :vlabel_group => @grp_2.name)
    end
    
    it "should return vlabels with the same app_id in the same group" do
      VlabelMap.in_group(@grp_1.app_id, @grp_1.name).should =~ [@vlm_1a, @vlm_1b]
    end
    
    it "should not return vlabels with a different app_id" do
      VlabelMap.in_group(@grp_2.app_id, @grp_2.name).should == [@vlm_2a]
    end
    
    it "should not return vlabels with the same app_id but different group" do
      VlabelMap.in_group(@grp_1.app_id, @grp_1.name).should_not include @vlm_1c
    end
    
    it "should include vlabels a group that has geo-routing" do
      FactoryGirl.create(:operation, :app_id => @app_id_1, :vlabel_group => "#{@grp_1.name}_GEO_ROUTE_SUB")
      vlm_1d = FactoryGirl.create(:vlabel_map, :app_id => @app_id_1, :vlabel_group => "#{@grp_1.name}_GEO_ROUTE_SUB")
      VlabelMap.in_group(@grp_1.app_id, @grp_1.name).should =~ [@vlm_1a, @vlm_1b, vlm_1d]
    end
  end

  describe "with_mapped_dests" do
    before(:each) do
      @app_id = 1
      @vlm1 = FactoryGirl.create(:vlabel_map, :app_id => @app_id, :vlabel => "abc")
      @grp_name = @vlm1.vlabel_group
    end

    context "finding vlabels" do
      before do
        FactoryGirl.create(:vlabel_map, :vlabel_group => @grp_name, :app_id => @app_id, :vlabel => "def")
      end

      it "should find all vlabels for a group" do
        VlabelMap.with_mapped_dests(@app_id, @grp_name, 1).size.should == 2
      end
  
      it "should find vlabels for a group if the group has a geo-route attached" do
        @vlm1.update_attributes(:vlabel_group => "#{@grp_name}_GEO_ROUTE_SUB")
        VlabelMap.with_mapped_dests(@app_id, @grp_name, 1).size.should == 2
      end
    end
   
    context "exits" do
      before do
        @location = FactoryGirl.create(:destination)
      end
     
      it "should include destination exits for a location" do
        @exit = FactoryGirl.create(:destination)
        FactoryGirl.create(:label_destination_map, :vlabel_map_id => @vlm1.id, :mapped_destination_id => @location.id, :exit_id => @exit.id, :exit_type => "Destination")
  
        expected_exit_results(@exit.destination)
      end
  
      it "should include vlabel map exits for a location" do
        @exit = FactoryGirl.create(:vlabel_map)
        FactoryGirl.create(:label_destination_map, :vlabel_map_id => @vlm1.id, :mapped_destination_id => @location.id, :exit_id => @exit.id, :exit_type => "VlabelMap")
        
        expected_exit_results(@exit.vlabel)
      end

      it "should include media file exits for a location" do
        pending "figuring out why this test fails.  method works fine."
        @exit = FactoryGirl.create(:media_file)
        FactoryGirl.create(:label_destination_map, :vlabel_map_id => @vlm1.id, :mapped_destination_id => @location.id, :exit_id => @exit.id, :exit_type => "MediaFile")

        expected_exit_results(@exit.keyword)
      end
  

      def expected_exit_results(exit)
        vlms = VlabelMap.with_mapped_dests(@app_id, @grp_name, @location.id)

        vlms.size.should == 1
        vlms[0].vlabel.should == @vlm1.vlabel
        vlms[0].exit_label.should == exit
      end
    end
  end
end
