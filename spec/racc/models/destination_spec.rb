require 'spec_helper'

describe Destination do

  describe "#find_by_property_name" do
    before do
      create_time = Time.now
      @did_prop = FactoryGirl.create(:destination_property, :app_id => 1103, :destination_property_name => 'DID-PSTN', :modified_time => create_time)
      @l3_prop = FactoryGirl.create(:destination_property, :app_id => 1103, :destination_property_name => 'LEVEL-3', :modified_time => create_time)
      @vail_prop = FactoryGirl.create(:destination_property, :app_id => 1103, :destination_property_name => 'VAIL_APP', :modified_time => create_time)
      @did = FactoryGirl.create(:destination, :app_id => 1103, :destination_property_name =>  'DID-PSTN', :modified_time => create_time + 1.minute)
      @l3 = FactoryGirl.create(:destination, :app_id => 1103, :destination_property_name => 'LEVEL-3', :modified_time => create_time + 2.minutes)
      @vail = FactoryGirl.create(:destination, :app_id => 1103, :destination_property_name => 'VAIL_APP', :modified_time => create_time + 3.minutes)
      @l3_2 = FactoryGirl.create(:destination, :app_id => 1103, :destination_property_name => 'LEVEL-3', :modified_time => create_time + 4.minutes)
    end

    it "should find destinations by destination_property_type" do
      Destination.find_by_property_name(1103, 'ALL').should == [@did, @l3, @vail, @l3_2]
      Destination.find_by_property_name(1103, 'DID-PSTN').should == [@did]
      Destination.find_by_property_name(1103, 'LEVEL-3').should == [@l3, @l3_2]
      Destination.find_by_property_name(1103, 'VAIL_APP').should == [@vail]
    end

    it "should limit the total results when the limit param is specified, and sort by modified_time in descending order" do
      Destination.find_by_property_name(1103, 'ALL', :limit => 2).should == [@l3_2, @vail]
    end
  end

  describe "validations" do
    before do
      @dest_prop = FactoryGirl.create(:destination_property, app_id: 5601)
      @destination = FactoryGirl.build(:destination, app_id: 5601)
    end

    it "should save" do
      @destination.save.should eql(true)
    end

    it "should return destination selects based on title" do
      FactoryGirl.create(:destination, :destination => 'T123456', :destination_title => 'EL-T123456', app_id: 5601)
      FactoryGirl.create(:destination, :destination => 'P123456', :destination_title => 'EL-P123456', app_id: 5601)

      Destination.selects("", 5601).length.should > 1
      Destination.selects("T", 5601).length.should == 1
    end

    it "should return a dli if the destination_attr is nil" do
      li = FactoryGirl.build(:li, app_id: 5601)
      @dli = FactoryGirl.create(:dli, :lis => [li], app_id: 5601)
      @destination.destination_attr = 'D'
      @destination.destination = @dli.value + "+029348230948"

      @destination.dli.should be_valid
    end

    it "should return nil" do
      li = FactoryGirl.build(:li)
      @dli = FactoryGirl.create(:dli, :lis => [li])
      @destination.destination_attr = 'N'
      @destination.destination = @dli.value + "+029348230948"

      @destination.dli.should be(nil)
    end
    
    it "should be invalid if the corresponding destination_property does not exist" do
      dest = Destination.new(:destination => '1234556666', :app_id => 2, :destination_title => 'test_title', :destination_property_name => 'NO_PROP' )
      dest.should_not be_valid
    end
    
    it "should allow valid destination titles" do
      ["hello", "a2-_'s %():.", "12345", "this is a valid title", "valid/this+and#123with&that", "one\\withabackslash"].each do |title|
        @destination.destination_title = title
        @destination.should be_valid
      end
    end
    
    it "should be invalid if the destination title has any leading or trailing spaces" do
      [" front space", "end space ", " both spaces ", "asfdasfsfdsfasfsafsfdasdf "].each do |title|
        @destination.destination_title = title
        @destination.should_not be_valid
      end
    end
    
    it "should allow a title between 1 and 64 characters" do
      long_title = ""
      64.times do
        long_title << "a"
      end
      [long_title, "h", "testing this string", 123].each do |title|
        @destination.destination_title = title
        @destination.should be_valid
      end
    end
    
    it "should not allow a title bigger than 64 characters" do
      title = ""
      65.times do
        title << "a"
      end
      @destination.destination_title = title
      @destination.should_not be_valid
    end
    
    it "should not allow a title with invisible characters" do
      ["new\nline", "carriagereturn\r", "\ttab", "asdfs
        sadf
          asdfsa"].each do |title|
        @destination.destination_title = title
        @destination.should_not be_valid
      end
    end
    
    it "should not allow a title with invalid characters" do
      ["*", "blah!blah", "$|h"].each do |title|
        @destination.destination_title = title
        @destination.should_not be_valid
      end      
    end
    
    it "should not allow commas or pipes (these cause problems for RACC and the Cache)" do
      ["testing, commas", ",", "h,", "testing|pipes", "|", "h|"].each do |title|
        @destination.destination_title = title
        @destination.should_not be_valid
      end
    end
    describe "hidden destination property" do
      before :each do
        @dest_prop.update_attribute(:hidden, true)
        @destination = FactoryGirl.build :destination, destination_property_name: @dest_prop.destination_property_name, app_id: @dest_prop.app_id
      end

      it "should not be valid" do
        expect(@destination).not_to be_valid
      end

    end
  end    

  describe "search_routed" do

    it "should find routed destinations for auto-search " do
      FactoryGirl.create(:destination_property, :app_id => 1103)
      FactoryGirl.create(:destination_property, :app_id => 8245, :destination_property_name => 'proptwo')
      destinations = {
        '8005551111' => FactoryGirl.create(:destination, :destination => "8005551111", :app_id => "1103"),
        '8005552222' => FactoryGirl.create(:destination, :destination => "8005552222", :app_id => "8245", :destination_property_name => 'proptwo'),
        '3125552222' => FactoryGirl.create(:destination, :destination => "3125552222", :app_id => "1103")
      }

      FactoryGirl.create(:racc_route_destination_xref, :exit => destinations['8005551111'], :app_id => "1103", :route_id => 1)
      FactoryGirl.create(:racc_route_destination_xref, :exit => destinations['8005552222'], :app_id => "8245", :route_id => 1)
      FactoryGirl.create(:racc_route_destination_xref, :exit => destinations['3125552222'], :app_id => "1103", :route_id => 1)

      Destination.search_routed("8", "1103").should == [ destinations['8005551111'] ]

      Destination.search_routed("2222", "8245").should == [ destinations['8005552222'] ]
    end

  end
  
  describe "in_vlabel_maps" do
    before(:each) do
      @group_name = 'active_vlm'
    end
    
    it "should only return active routes where the destination is used" do
      create_active_route(@group_name)
      dest2 = FactoryGirl.create(:destination, :destination_property_name => FactoryGirl.create(:destination_property, :destination_property_name => 'proptwo').destination_property_name)
      
      @dest.in_vlabel_maps.should == [@vlm]
      dest2.in_vlabel_maps.should == []
    end
    
    it "should not return any active routes in default groups" do
      create_active_route(@group_name)
      @g.update_attributes(:group_default => 1)
      @dest.in_vlabel_maps.should == []
    end
    
    it "should return active routes if there is a geo-route group attached" do
      grp_name = "#{@group_name}_GEO_ROUTE_SUB"
      create_active_route(grp_name)
      FactoryGirl.create(:operation, :vlabel_group => grp_name, :operation => 16)
      
      @dest.in_vlabel_maps.should == [@vlm]
    end
    
    def create_active_route(_name)
      @dest = FactoryGirl.create(:destination, :destination_property_name => FactoryGirl.create(:destination_property).destination_property_name)
      @g = FactoryGirl.create(:group, :name => 'b_group', :category => 'b')
      @vlm = FactoryGirl.create(:vlabel_map, :vlabel => _name, :vlabel_group => @g.name)
      @rr = FactoryGirl.create(:racc_route, :route_name => _name)
      @xref = FactoryGirl.create(:racc_route_destination_xref, :route_id => @rr.id, :exit => @dest)
    end
  end

  describe "in_frontend_groups" do

    it "should find front end groups for a destination" do
      destination = FactoryGirl.create(:destination, :destination_property_name => FactoryGirl.create(:destination_property).destination_property_name)
      grp_name = "F_Default_Group"
      default_group = FactoryGirl.create(:group, :name => grp_name, :category => 'f', :group_default => true)
      vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel => "F_Default_Route", :vlabel_group => default_group.name)
      
      racc_route = FactoryGirl.create(:racc_route, :route_name => vlabel_map.vlabel)
      xref = FactoryGirl.create(:racc_route_destination_xref, :route_id => racc_route.id, :exit => destination)
      
      group = FactoryGirl.create(:group, :category => 'f')
      op = group.operation
      op.newop_rec = "F_Default_Route"
      op.save
      
      destination.in_frontend_groups.should == [group]
    end

  end
  
  describe "in_preroute_groups" do
    before do
      @destination = FactoryGirl.create(:destination)
      @preroute = FactoryGirl.create(:preroute_group)
      @route = FactoryGirl.create(:racc_route, route_name: @preroute.route_name)
      @route_xref = FactoryGirl.create(:racc_route_destination_xref,
        racc_route: @route, exit: @destination)
      
      @ignore_route = FactoryGirl.create(:racc_route)
      @ignore_dest = FactoryGirl.create(:destination)
      FactoryGirl.create(:racc_route_destination_xref,
        :racc_route => @ignore_route, :exit => @ignore_dest)
    end
    
    it "finds preroute groups whose route contains this destination" do
      @destination.in_preroute_groups.should eq([@preroute])
    end
    
    it "does not return preroute groups that do not contain this destination" do
      @destination.in_preroute_groups.should_not include(@ignore_route)
    end
  end
  
  describe "in_georoute_groups" do
    
    before :each do
      @destination = FactoryGirl.create(:destination, :destination_property_name => FactoryGirl.create(:destination_property).destination_property_name)
      @ani_group = FactoryGirl.create(:ani_group)
      @ani_map = FactoryGirl.create(:ani_map, :ani_group => @ani_group)
      @geo_route_group = FactoryGirl.create(:geo_route_group)
      @racc_route = FactoryGirl.create(:racc_route)
      @racc_route_destination_xref = FactoryGirl.create(:racc_route_destination_xref, :racc_route => @racc_route, :exit => @destination)
      @geo_route_ani_xref = FactoryGirl.create(:geo_route_ani_xref, :ani_group => @ani_group, :geo_route_group => @geo_route_group, :route_name => @racc_route.route_name)
    end
    
    it "returns nothing when the destination is not assigned to any geo-routes" do
      @unused_destination = FactoryGirl.create(:destination)
      @unused_destination.in_georoute_groups.should == []
    end
    
    it "returns any geo-route groups the destination is assigned to" do
      @destination.in_georoute_groups.should == [@geo_route_group]
    end
    
  end
  
  describe "in_survey_groups" do
    
    before :each do
      @destination = FactoryGirl.create(:destination, :destination_property_name => FactoryGirl.create(:destination_property).destination_property_name)
      @racc_route = FactoryGirl.create(:racc_route)
      @racc_route_destination_xref = FactoryGirl.create(:racc_route_destination_xref, :racc_route => @racc_route, :exit => @destination)
      @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel => @racc_route.route_name)
      @survey_group = FactoryGirl.create(:survey_group, :survey_vlabel => @racc_route.route_name)
    end
    
    it "returns nothing when the destination is not assigned to any survey groups" do
      @unused_destination = FactoryGirl.create(:destination)
      @unused_destination.in_survey_groups.should == []
    end
    
    it "returns any survey group to which the destination is assigned" do
      @destination.in_survey_groups.should == [@survey_group]
    end
    
  end

  describe "in_default_route_group" do
    it "should return an active route from a Default Group" do
      create_active_route("active_route")
      @g.update_attributes(:group_default => 1)
      @dest.in_vlabel_maps_default_groups.should == [@vlm]
    end

    it "should not return an active route from the default Group" do
      create_active_route("active_route")
      @g.update_attributes(:group_default => 0)
      @dest.in_vlabel_maps_default_groups.should == []
    end
    
    def create_active_route(_name)
      @dest = FactoryGirl.create(:destination, :destination_property_name => FactoryGirl.create(:destination_property).destination_property_name)
      @g = FactoryGirl.create(:group, :name => _name, :category => 'b')
      @vlm = FactoryGirl.create(:vlabel_map, :vlabel => _name, :vlabel_group => @g.name)
      @rr = FactoryGirl.create(:racc_route, :route_name => _name)
      @xref = FactoryGirl.create(:racc_route_destination_xref, :route_id => @rr.id, :exit => @dest)
    end
      
  end
  
  describe "dnis" do
    it "returns the sequence of numbers (if any) that terminates this destination" do
      @test_destination = FactoryGirl.build(:destination, :destination => "123Sample Value 8005558245")
      @test_destination.dnis.should == "8005558245"
    end
    
    it "returns nil if the destination is not terminated by a digit" do
      @test_destination = FactoryGirl.build(:destination, :destination => "Marc Test")
      @test_destination.dnis.should == nil
    end
    
    it "will correctly seperate the dnis from the first part of the destination separated by a '+' sign" do
      @test_destination = FactoryGirl.build(:destination, :destination => "58238+8005558245")
      @test_destination.dnis.should == "8005558245"
    end
  end
  
  describe "find_valid" do
    before :each do
      @search_term = "test"
      @dp = FactoryGirl.create(:destination_property)
    end
    
    context "searching destinations" do
      it "searches for the phrase in destinations' title'" do
        dest = FactoryGirl.create(:destination, :destination_title => "test_search", :app_id => 1, :destination_property_name => @dp.destination_property_name)
        results = Destination.find_valid(1, @search_term)
        results.should include(dest)
      end

      it "searches for the phrase in destinations' name'" do
        dest = FactoryGirl.create(:destination, :destination => "test_search", :app_id => 1, :destination_property_name => @dp.destination_property_name)
        results = Destination.find_valid(1, @search_term)
        results.should include(dest)
      end

      it "is case insensitive" do
        dest = FactoryGirl.create(:destination, :destination => "TEST_SEARCH", :app_id => 1, :destination_property_name => @dp.destination_property_name)
        results = Destination.find_valid(1, @search_term)
        results.should include(dest)
      end
      
      it "should return destinations in order by destination" do
        dest1 = FactoryGirl.create(:destination, :destination => "9991234567+123")
        dest2 = FactoryGirl.create(:destination, :destination => "9991234567+565666")
        dest3 = FactoryGirl.create(:destination, :destination => "9991234567+2553222")
        dest = FactoryGirl.create(:destination, :destination => "9991234567")
        
        Destination.find_valid(1, "9991234567").should == [dest, dest1, dest3, dest2]
      end
    end
    
    context "verifying destinations" do
      it "should return only destinations that are an exact match" do
        wrong_dest = FactoryGirl.create(:destination, :destination => "test_search", :app_id => 1, :destination_property_name => @dp.destination_property_name)
        correct_dest = FactoryGirl.create(:destination, :destination => @search_term, :app_id => 1, :destination_property_name => @dp.destination_property_name)
        results = Destination.find_valid(1, @search_term, true)
        results.should include(correct_dest)
        results.should_not include(wrong_dest)
      end
      
      it "should only verify against the destination, not the destination title" do
        wrong_dest = FactoryGirl.create(:destination, :destination_title => @search_term, :app_id => 1, :destination_property_name => @dp.destination_property_name)
        Destination.find_valid(1, @search_term, true).should_not include(wrong_dest)
      end
      
      it "should return DIVR destinations that have an active DIVR attached" do
        divr_123 = FactoryGirl.create(:dynamic_ivr, :state => "Active")
        @dp.update_attributes(:destination_property_name => DestinationProperty::DIVR_DESTINATION_PROPERTY)
        divr_dest = FactoryGirl.create(:destination, :destination => "dest_divr_123", :destination_property_name => @dp.destination_property_name)
        divr_dest.dynamic_ivr = divr_123
        divr_dest.save
        Destination.find_valid(1, "dest_divr_123", true).should == [divr_dest]
      end
      
      it "should not return DIVR destinations that do not have a DIVR attached" do
        @dp.update_attributes(:destination_property_name => DestinationProperty::DIVR_DESTINATION_PROPERTY)
        divr_dest = FactoryGirl.create(:destination, :destination => "divr_123", :destination_property_name => @dp.destination_property_name)
        Destination.find_valid(1, "divr_123", true).should == []
      end
    end
  end
  
  describe "join_destination_name" do
    before :each do
      FactoryGirl.create(:destination_property)
    end
    
    it "does nothing if the destination_name attr is not an Array" do
      dest = FactoryGirl.create(:destination, :destination => "Marc_Test")
      dest.destination_name = 5
      dest.valid?
      dest.destination.should == "Marc_Test"
    end
    
    it "joins the strings in the Array at destination name and assigns the result to destination before validating the object" do
      dest = FactoryGirl.build(:destination, :destination => nil)
      dest.destination_name = [847, 691, "5602"]
      dest.valid?
      dest.destination.should == "8476915602"
    end
    
    it "will not override an existing destination name" do
      dest = FactoryGirl.build(:destination, :destination => "Marc_Test")
      dest.destination_name = [847, 691, "5602"]
      dest.valid?
      dest.destination.should == "Marc_Test"
    end
  end
  
  describe "Deleting destinations" do
    it "deletes all web_routing_exits that use the deleted destination" do
      # Note: We can delete all web_routing_exits b/c the destination 
      # cannot be deleted if it is currently being used
      FactoryGirl.create(:destination_property)
      dest = FactoryGirl.create(:destination, :destination => "dest_one")
      routing_exit = FactoryGirl.create(:routing_exit, :exit_id => dest.id, :exit_type => "Destination",
                                        :routing => FactoryGirl.create(:routing,
                                        :time_segment => FactoryGirl.create(:time_segment, 
                                        :profile => FactoryGirl.create(:profile, :sun => true))))
      
      dest.destroy
      RoutingExit.find_by_id(routing_exit.id).should == nil
    end
  end
  
  describe "match_destination_to_validation_format" do
    
    context "10_DIGIT" do
      before(:each) do
        # Regex is copied from the db.  Update specs if this changes.
        FactoryGirl.create(:destination_validation_format)
        dp = FactoryGirl.create(:destination_property, :validation_format => '10_DIGIT')
        @dest = FactoryGirl.build(:destination, :destination_property_name => dp.destination_property_name, :app_id => dp.app_id)        
      end

      it "matches valid 10-digit destinations" do
        @dest.destination = '1234567890'
        @dest.should be_valid
      end
      
      it "does not match non-10-digit destinations" do
        oversized_dest = ""
        65.times do
          oversized_dest << '1'
        end

        ['12355', 'abcdefghij', nil, '', oversized_dest].each do |dest|
          @dest.destination = dest
          @dest.should_not be_valid
        end
      end
    end
    
    context "TRUNK_DNIS" do
      before(:each) do
        # Regex is copied from the db.  Update specs if this changes.
        FactoryGirl.create(:destination_validation_format, :name => 'TRUNK_DNIS', :regex => '^[0-9]{10}\+[0-9]{2,14}$')
        dp = FactoryGirl.create(:destination_property, :validation_format => 'TRUNK_DNIS')
        @dest = FactoryGirl.build(:destination, :destination_property_name => dp.destination_property_name, :app_id => dp.app_id)        
      end
    
      it "matches valid destinations" do
        ['1234567890+12', '5584889666+123556', '6655596333+45559556965669'].each do |dest|
          @dest.destination = dest
          @dest.should be_valid
        end
      end
      
      it "does not match invalid destinations" do
        oversized_dest = "1234567890+"
        55.times do
          oversized_dest << '1'
        end
        
        ['12355', 'abcdefghij', nil, '', '554856+1234', '+12345678', '1234567890+123456789012345', oversized_dest].each do |dest|
          @dest.destination = dest
          @dest.should_not be_valid
        end
      end
    end

    context "TRUNK_DNIS_WITH_MEGA" do
      before(:each) do
        # Regex is copied from the db.  Update specs if this changes.
        FactoryGirl.create(:destination_validation_format, :name => 'TRUNK_DNIS_WITH_MEGA', :regex => '^[\w\.\-\ ]{1,64}\+[0-9]{2,14}$')
        dp = FactoryGirl.create(:destination_property, :validation_format => 'TRUNK_DNIS_WITH_MEGA')
        @dest = FactoryGirl.build(:destination, :destination_property_name => dp.destination_property_name, :app_id => dp.app_id)        
      end
    
      it "matches valid destinations" do
        ['1234567890+12', 'ABC+123556', '665 55-96.33_3+45559556965669',
          'Trial Mega Trunk+37008'].each do |dest|
          @dest.destination = dest
          @dest.should be_valid
        end
      end
      
      it "does not match invalid destinations" do
        oversized_dest = "1234567890+"
        55.times do
          oversized_dest << '1'
        end
        
        ['12355', 'abcdefghij', nil, '', '+12345678', '123+abc+1234556', '1234+882221234567899',
          '$#%#$%#+1234', oversized_dest].each do |dest|
          @dest.destination = dest
          @dest.should_not be_valid
        end
      end
    end

    
    context "SIP_URL" do
      before(:each) do
        # Regex is copied from the db.  Update specs if this changes.
        FactoryGirl.create(:destination_validation_format, :name => 'SIP_URL', :regex => '^(sip\:)??[a-z0-9_+\-]+(\.[a-z0-9_+\-]+)*@([a-z0-9]+([a-z0-9]+|\.[a-z0-9]+|\-[a-z0-9]+)*\.(aero|arpa|asia|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel|vail|[a-z]{2})|([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}))(:[0-9]{1,5})?$')
        dp = FactoryGirl.create(:destination_property, :validation_format => 'SIP_URL')
        @dest = FactoryGirl.build(:destination, :destination_property_name => dp.destination_property_name, :app_id => dp.app_id)        
      end
    
      it "matches valid destinations" do
        ['123abc@domain.com', 'a@example.com', '56@123.4.145.15', 'sip:hello@lkds.asdf.com', 'sip:01001@67.409.233.101', 'sip:123122@afda.vail'].each do |dest|
          @dest.destination = dest
          @dest.should be_valid
        end
      end
      
      it "does not match invalid destinations" do
        oversized_dest = ""
        55.times do
          oversized_dest << '1'
        end
        oversized_dest << "@tests.com"
        
        ['12355', 'abcdefghij', nil, '', '@example.com', '123@1234.123', '$#%#@example.com', oversized_dest, 'sip:sip:@blah.com'].each do |dest|
          @dest.destination = dest
          @dest.should_not be_valid
        end
      end
    end
    
    context "IP_ADDRESS" do
      before(:each) do
        # Regex is copied from the db.  Update specs if this changes.
        FactoryGirl.create(:destination_validation_format, :name => 'IP_ADDRESS', :regex => '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')
        dp = FactoryGirl.create(:destination_property, :validation_format => 'IP_ADDRESS')
        @dest = FactoryGirl.build(:destination, :destination_property_name => dp.destination_property_name, :app_id => dp.app_id)        
      end
    
      it "matches valid destinations" do
        ['1.12.123.123', '123.1.22.23', '32.123.2.2'].each do |dest|
          @dest.destination = dest
          @dest.should be_valid
        end
      end
      
      it "does not match invalid destinations" do
        oversized_dest = ""
        dest_part = ""
        17.times do
          dest_part << '2'
        end
        oversized_dest = dest_part + '.' + dest_part + '.' + dest_part + '.' + dest_part
        
        ['12355', 'abcdefghij', nil, '', '1234.344.2.33', '23.22.3', '66.33', '13.2.11.256', oversized_dest].each do |dest|
          @dest.destination = dest
          @dest.should_not be_valid
        end
      end
    end
    
    context "ALL" do
      before(:each) do
        # Regex is copied from the db.  Update specs if this changes.
        FactoryGirl.create(:destination_validation_format, :name => 'ALL', :regex => '^.+$')
        dp = FactoryGirl.create(:destination_property, :validation_format => 'ALL')
        @dest = FactoryGirl.build(:destination, :destination_property_name => dp.destination_property_name, :app_id => dp.app_id)        
      end
      
      it "matches valid destinations" do
        ['abc', '@#$|%*-./ad', '123', '1a3d4v ASADF97893jf'].each do |dest|
          @dest.destination = dest
          @dest.should be_valid
        end
      end
      
      it "does not match invalid destinations" do
        oversized_dest = ""
        65.times do
          oversized_dest << '1'
        end
        
        ['', nil, oversized_dest].each do |dest|
          @dest.destination = dest
          @dest.should_not be_valid
        end
      end
    end

    context "INTERNATIONAL" do
      before(:each) do
        FactoryGirl.create(:destination_validation_format, :name => 'INTERNATIONAL', :regex => '^\+[0-9]{4,63}$')
        dp = FactoryGirl.create(:destination_property, :validation_format => 'INTERNATIONAL')
        @dest = FactoryGirl.build(:destination, :destination_property_name => dp.destination_property_name, :app_id => dp.app_id)        
      end
      it "matches a valid destination" do
        @dest.destination = '+1234567890123'
        @dest.should be_valid
      end

      it "does not match invalid destinations" do
        long_string = "+#{'a' * 64}"
        ['12345', '+123', '808+8080', long_string].each do |dest|
          @dest.destination = dest
          @dest.should_not be_valid
        end
      end
    end

  end

  describe 'is_queue?' do
    it 'should return true if the destination is a queue' do
      d = FactoryGirl.build(:destination, :destination_property_name => Destination::QUEUE_DESTINATION_PROPERTY)
      d.is_queue?.should be_true
    end
    
    it 'should return false if the destination is not a queue' do
      d = FactoryGirl.build(:destination, :destination_property_name => 'NETWORK_APP')
      d.is_queue?.should be_false
    end
  end
  
  describe 'routable?' do
    before do
      @dest = Destination.new
    end
    
    it 'will return true if destination is not a divr' do
      @dest.should_receive(:is_divr?).and_return false
      @dest.should_not_receive(:dynamic_ivr)
      @dest.routable?.should be_true
    end
    
    it 'will return true if destination is a divr and there are divrs attached' do
      @dest.should_receive(:is_divr?).and_return true
      @dest.should_receive(:dynamic_ivr).and_return DynamicIvr.new
      @dest.routable?.should be_true
    end
    
    it 'will return false if destination is a divr and no divrs are attached' do
      @dest.should_receive(:is_divr?).and_return true
      @dest.should_receive(:dynamic_ivr).and_return nil
      @dest.routable?.should be_false
    end
  end
  
  describe 'remove_routing_exit_errors' do
    it 'should remove errors related to this destination' do
      d = Destination.new(:destination => '12345')
      RaccError.create(:error_message => "Destination #{d.destination} does not have a Dynamic IVR attached.")
      RaccError.create(:error_message => "Destination #{d.destination * 2} does not have a Dynamic IVR attached.")
      d.send(:remove_routing_exit_errors)
      RaccError.count.should == 1
    end
  end
  
  describe 'generate_routing_exit_errors' do
    before do
      @dest = FactoryGirl.build(:destination)
      @routing1, @routing2 = Routing.new, Routing.new
      @dest.stub(:routings).and_return [@routing1, @routing1, @routing2]
    end
    
    it 'will pass through if the destination is not a divr destination' do
      @dest.should_receive(:is_divr?).and_return false
      @routing1.should_not_receive(:generate_error)
      @routing2.should_not_receive(:generate_error)
      @dest.send(:generate_routing_exit_errors)
    end
    
    it 'will pass through if a divr destination remains valid' do
      @dest.should_receive(:is_divr?).and_return true
      @dest.stub_chain(:dynamic_ivr, :nil?).and_return false
      @routing1.should_not_receive(:generate_error)
      @routing2.should_not_receive(:generate_error)
      @dest.send(:generate_routing_exit_errors)
    end
    
    it 'will generate routing exits errors if a divr destination was invalidated' do
      @dest.should_receive(:is_divr?).and_return true
      @dest.stub_chain(:dynamic_ivr, :nil?).and_return true
      @routing1.should_receive(:generate_error).once
      @routing2.should_receive(:generate_error).once
      @dest.send(:generate_routing_exit_errors)
    end
  end
  
  describe "routed?" do
    before do
      @dest = FactoryGirl.create(:destination)
    end

    it "should return true if the destination is used in a route" do
      route = FactoryGirl.create(:racc_route)
      FactoryGirl.create(:racc_route_destination_xref, exit: @dest, route_id: route.id)
      
      @dest.routed?.should == true
    end
    
    it "should return false if the destination is NOT used in a route" do
      @dest.routed?.should == false
    end
  end
  
  describe "mapped?" do
    before(:each) do
      @dest = FactoryGirl.create(:destination)
    end
    it "should return true if the destination is used as a location" do
      FactoryGirl.create(:label_destination_map, :mapped_destination_id => @dest.id)
      @dest.mapped?.should == true
    end

    it "should return true if the destination is used as an exit" do
      FactoryGirl.create(:label_destination_map, :exit_id => @dest.id, :exit_type => "Destination")
      @dest.mapped?.should == true
    end
    
    it "should return false if the destination is NOT used in any mapping" do
      @dest.mapped?.should == false
    end
  end

  describe :mappable? do
    before do
      @destination = Destination.new
      @destination.stub(:destination_property).and_return destination_property
    end

    subject { @destination.mappable? }
    
    context "when destination property allows mapping" do
      let(:destination_property) { stub(:allows_mapping? => true) }
      it { should be_true }
    end

    context "when destination property does not allow mapping" do
      let(:destination_property) { stub(:allows_mapping? => false) }
      it { should be_false }
    end
    
    context "when no destination property is attached" do
      let(:destination_property) { nil }
      it { should be_false }
    end
  end
  
  describe "format_for_search" do
    context "for destinations" do
      before(:each) do
        dest = FactoryGirl.create(:destination)
        @dest = Destination.searches(dest.app_id, dest.destination).with_property.first
      end
      
      it "should set the path to the destination show page" do
        @dest.format_for_search[:path][:method].should == :destination_path
      end
      
      it "should set the meta key to 'Destination'" do
        @dest.format_for_search.has_key?(:destination)
      end
    end
    
    context "for locations" do
      before(:each) do
        loc = FactoryGirl.create(:destination)
        loc.destination_property.update_attributes(:dtype => "M")
        @loc = Destination.searches(loc.app_id, loc.destination).with_property.first
      end
      
      it "should set the path to the edit mapped destinations page" do
        @loc.format_for_search[:path][:method].should == :edit_label_destination_map_path
      end
      
      it "should set the meta key to 'Location'" do
        @loc.format_for_search.has_key?(:location)
      end
    end
  end
end
