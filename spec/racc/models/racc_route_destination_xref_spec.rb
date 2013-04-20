require 'spec_helper'

describe RaccRouteDestinationXref do
  describe :validations do
    before do
      FactoryGirl.create(:destination_property)
      @xref = FactoryGirl.create(:racc_route_destination_xref)
    end
    
    it "should be valid with valid attributes" do
      @xref.should be_valid
    end
    
    it "should be invalid without an app_id" do
      ThreadLocalHelper.thread_local_app_id = nil
      @xref.app_id = nil
      @xref.should_not be_valid
    end
    
    it "should be invalid without a route_id" do
      @xref.route_id = nil
      @xref.should_not be_valid
    end
    
    it "should be invalid without a route_order" do
      @xref.route_order = nil
      @xref.should_not be_valid
    end
    
    it "should be invalid with a modified_by longer than 64 chars" do
      @xref.modified_by = "a" * 65
      @xref.should_not be_valid
    end
  end
  
  describe :reorder do
    it "should reorder entities such that route_order values start at 1 and are sequential" do

      RaccRouteDestinationXref.delete_all

      r = FactoryGirl.create(:racc_route_destination_xref)
      r.save

      r = FactoryGirl.create(:racc_route_destination_xref, :route_order => 2)
      r.save

      r = FactoryGirl.create(:racc_route_destination_xref, :route_order => 5)
      r.save

      r = FactoryGirl.create(:racc_route_destination_xref, :route_order => 4)
      r.save

      RaccRouteDestinationXref.reorder(1, 1)

      xrefs = RaccRouteDestinationXref.find(:all, :conditions => ["app_id = ? and route_id = ?", 1, 1])

      xrefs.length.should == 4

      xrefs.each_with_index {|xref, order| 
        xref.route_order.should == order + 1
      }
    end
  end

  describe :routed_to, slow: true do
    it "scopes to the given type" do
      FactoryGirl.create(:racc_route_destination_xref, exit_type: "Destination")
      FactoryGirl.create(:racc_route_destination_xref, exit_type: "VlabelMap")
      RaccRouteDestinationXref.routed_to("Destination").should have(1).item
    end
  end
end
