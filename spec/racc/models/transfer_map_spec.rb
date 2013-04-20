require File.dirname(__FILE__) + '/../spec_helper'

describe TransferMap do

  describe "validation" do
    
    before(:each) do
      @route = FactoryGirl.create(:racc_route, :route_name => "Test Route for Transfer Map")
      @transfer_map = TransferMap.new
    end

    it "should be valid" do
      @transfer_map.app_id = 1
      @transfer_map.transfer_string = "123ABCD"
      @transfer_map.vlabel = @route.route_name
      @transfer_map.should be_valid
    end
  
    it "should require app id to save" do
      @transfer_map.transfer_string = "123ABCD"
      @transfer_map.vlabel = "test"
      @transfer_map.should_not be_valid
    end
  
    it "should require transfer string to save" do
      @transfer_map.app_id = 1
      @transfer_map.vlabel = @route.route_name
      @transfer_map.should_not be_valid
    end
  
    it "should require vlabel to save" do
      @transfer_map.app_id = 1
      @transfer_map.transfer_string = "123ABCD"
      @transfer_map.should_not be_valid
    end
  
    it "should not allow duplicate transfer strings per app id" do
      @transfer_map.app_id = 1
      @transfer_map.transfer_string = "123ABCD"
      @transfer_map.vlabel = @route.route_name
      @transfer_map.modified_time = Time.now
      @transfer_map.save
    
      @transfer_map_dupe = TransferMap.new
      @transfer_map_dupe.app_id = 1
      @transfer_map_dupe.transfer_string = "123ABCD"
      @transfer_map_dupe.vlabel = @route.route_name
      @transfer_map_dupe.modified_time = Time.now
      @transfer_map_dupe.should_not be_valid
    end
    
    it "fails validation if the route does not exist" do
      transfer_map = FactoryGirl.build(:transfer_map, :vlabel => "Invalid Route")
      transfer_map.should_not be_valid
    end
  end
  
  describe "scope :containing" do
    before :each do
      #sorted by transfer_string ASC
      @route = FactoryGirl.create(:racc_route)
      @tms = [FactoryGirl.create(:transfer_map, :transfer_string => 103, :vlabel => @route.route_name), FactoryGirl.create(:transfer_map, :transfer_string => 3, :vlabel => @route.route_name), FactoryGirl.create(:transfer_map, :transfer_string => 303, :vlabel => @route.route_name),
             FactoryGirl.create(:transfer_map, :transfer_string => 31, :vlabel => @route.route_name), FactoryGirl.create(:transfer_map, :transfer_string => 33, :vlabel => @route.route_name)]
    end
  
    it "should return all transfer maps whose transfer string containing the specified string" do
      TransferMap.containing(@tms[0].app_id, '3').should == @tms
    end
  
    it "should exclude transfer maps whose transfer string does NOT contain the specified string" do 
      FactoryGirl.create(:transfer_map, :transfer_string => "What a great string!", :vlabel => @route.route_name)
      TransferMap.containing(@tms[0].app_id, '3').should == @tms
    end
  
    it "should exclude transfer maps whose app_id is different than the one specified" do
      route = FactoryGirl.create(:racc_route, :app_id => 2)
      FactoryGirl.create(:transfer_map, :transfer_string => 38, :app_id => 2, :vlabel => route.route_name)
      TransferMap.containing(@tms[0].app_id, '3').should == @tms
    end
  
    it "should return no more than 10 results" do
      11.times do |i|
        FactoryGirl.create(:transfer_map, :transfer_string => "333#{i}", :vlabel => @route.route_name)
      end
      maps = TransferMap.containing(@tms[0].app_id, '3')
      #The call to #size on ActiveRecord or a collection of ActiveRecord yields a 
      #   SQL query 'SELECT count(*) ....' that ignores any limit set.  The ugliness
      #   below lets us verify that the limit was recognized by the query run by this 
      #   named scope.  Enjoy! 
      counter = 0
      maps.each do
        counter += 1
      end
      counter.should == 10
    end
  end
  
  describe "with_vlabel_maps_and_active_packages" do

    before(:each) do
      @app_id = 4321
      @group = FactoryGirl.create(:group, :category => 'b', :group_default => false, :app_id => @app_id)
      @vlabel_map = FactoryGirl.create(:vlabel_map, :app_id => @app_id, :vlabel => '112233', :vlabel_group => @group.name)
      FactoryGirl.create(:racc_route, :route_name => @vlabel_map.vlabel, :app_id => @app_id)
      @active_package = FactoryGirl.create(:package, :vlabel_map => @vlabel_map, :active => true, :app_id => @app_id)
      FactoryGirl.create(:package, :vlabel_map => @vlabel_map, :active => false, :app_id => @app_id)
      @tm = FactoryGirl.create(:transfer_map, :vlabel => @vlabel_map.vlabel, :app_id => @app_id, :transfer_string => 'apple')
    end
    
    it "should find the corresponding group, vlabel map, and active package" do
      tm = TransferMap.with_vlabel_maps_and_active_packages(@app_id)[0]
      tm.group_id.to_s.should == @group.id.to_s
      tm.vlabel_map_id.to_s.should == @vlabel_map.id.to_s
      tm.active_package_id.to_s.should == @active_package.id.to_s
    end
    
    it "should find the transfer map if the transfer string is passed in" do
      transfer_map = FactoryGirl.create(:transfer_map, :vlabel => @vlabel_map.vlabel, :app_id => @app_id, :transfer_string => 'hello')
      
      TransferMap.with_vlabel_maps_and_active_packages(@app_id, 1, 'hello')[0].should == transfer_map
    end

    # NOTE: There's an issue with SQL Server and the limit clause in Rails 3 (see TransferMap#with_vlabel_maps_and_active_packages).  
    # Until that is figured out, the limiting is done on the controller.
    # it "should find the exact number of transfer maps if a limit is passed in" do
    #   FactoryGirl.create(:transfer_map, :vlabel => @vlabel_map.vlabel, :app_id => @app_id, :transfer_string => 'two')
    #   FactoryGirl.create(:transfer_map, :vlabel => @vlabel_map.vlabel, :app_id => @app_id, :transfer_string => 'three')
    #   
    #   TransferMap.with_vlabel_maps_and_active_packages(@app_id, 2).size.should == 2
    #   TransferMap.with_vlabel_maps_and_active_packages(@app_id).size.should == 3
    # end
    
    it "should get the transfer maps in recent order if a limit is passed in and in transfer string order if a limit is not passed in" do
      FactoryGirl.create(:transfer_map, :vlabel => @vlabel_map.vlabel, :app_id => @app_id, :transfer_string => 'abcd', :modified_time => Time.now + 1.minute)
      FactoryGirl.create(:transfer_map, :vlabel => @vlabel_map.vlabel, :app_id => @app_id, :transfer_string => 'cherry', :modified_time => Time.now + 2.minutes)
    
      TransferMap.with_vlabel_maps_and_active_packages(@app_id, 3)[0].transfer_string.should == 'cherry'
      TransferMap.with_vlabel_maps_and_active_packages(@app_id)[0].transfer_string.should == 'abcd'
    end
    
    it "should get transfer maps that have routes with a geo-route group" do
      FactoryGirl.create(:operation, :vlabel_group => "#{@group.name}_GEO_ROUTE_SUB", :app_id => @app_id)
      geo_vlabel_map = FactoryGirl.create(:vlabel_map, :app_id => @app_id, :vlabel => 'geo vlabel', :vlabel_group => "#{@group.name}_GEO_ROUTE_SUB")
      FactoryGirl.create(:racc_route, :route_name => geo_vlabel_map.vlabel, :app_id => @app_id)
      FactoryGirl.create(:package, :vlabel_map => geo_vlabel_map, :active => true, :app_id => @app_id)
      geo_tm = FactoryGirl.create(:transfer_map, :vlabel => geo_vlabel_map.vlabel, :app_id => @app_id, :transfer_string => 'pear')

      tms = TransferMap.with_vlabel_maps_and_active_packages(@app_id)
      
      tms.should =~ [@tm, geo_tm]
      tms.map{ |tm| tm.group_id }.should_not include(nil)
    end
        
  end
end
