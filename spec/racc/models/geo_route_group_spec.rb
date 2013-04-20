require File.dirname(__FILE__) + '/../spec_helper'

describe GeoRouteGroup do
  describe '#uniqueness_of_anis' do
    before :each do
      @geo_route_group = FactoryGirl.create(:geo_route_group)
      @ani_group_1 = FactoryGirl.create(:ani_group)
      
      @xref_1 = FactoryGirl.create(:geo_route_ani_xref, :geo_route_group => @geo_route_group, :ani_group => @ani_group_1)
      @ani_map_1 = FactoryGirl.create(:ani_map, :ani_group => @ani_group_1)
    end
    
    it 'should not allow addition of an AniGroup with a conflicting ani' do
      ani_group_2 = FactoryGirl.create(:ani_group)
      xref_2 = FactoryGirl.create(:geo_route_ani_xref, :geo_route_group => @geo_route_group, :ani_group => ani_group_2)
      ani_map_2 = FactoryGirl.create(:ani_map, :ani_group => ani_group_2)
      
      @geo_route_group.reload
      @geo_route_group.valid?.should == false
    end
    
    it 'should allow addition of an AniGroup without a conflicting ani' do
      ani_group_2 = FactoryGirl.create(:ani_group)
      xref_2 = FactoryGirl.create(:geo_route_ani_xref, :geo_route_group => @geo_route_group, :ani_group => ani_group_2)
      ani_map_2 = FactoryGirl.create(:ani_map, :ani_group => ani_group_2, :ani => '123')
    
      @geo_route_group.reload
      @geo_route_group.valid?.should == true
    end
  end
  
  describe '#uniqueness_of_ani_groups' do
    before :each do
      @geo_route_group = FactoryGirl.create(:geo_route_group)
      @ani_group_1 = FactoryGirl.create(:ani_group)
      
      FactoryGirl.create(:destination_property)
      @destination = FactoryGirl.create(:destination)
      
      @xref_1 = FactoryGirl.create(:geo_route_ani_xref, :geo_route_group => @geo_route_group, :ani_group => @ani_group_1)
    end
    
    it 'should not allow addition of the same AniGroup more than once' do
      xref_2 = FactoryGirl.create(:geo_route_ani_xref, :geo_route_group => @geo_route_group, :ani_group => @ani_group_1)
      
      @geo_route_group.reload
      @geo_route_group.valid?.should == false
    end
    
    it 'should allow two different AniGroups to be added' do
      ani_group_2 = FactoryGirl.create(:ani_group)
      xref_2 = FactoryGirl.create(:geo_route_ani_xref, :geo_route_group => @geo_route_group, :ani_group => ani_group_2)

      @geo_route_group.reload
      @geo_route_group.valid?.should == true
    end
  end
  
  describe 'ANI rules' do
    before(:each) do
      @geo_route_group = FactoryGirl.create(:geo_route_group)
      @ani_group_1 = FactoryGirl.create(:ani_group)
      @ani_group_2 = FactoryGirl.create(:ani_group)      
      @xref_1 = FactoryGirl.create(:geo_route_ani_xref, :geo_route_group => @geo_route_group, :ani_group => @ani_group_1)
      @xref_2 = FactoryGirl.create(:geo_route_ani_xref, :geo_route_group => @geo_route_group, :ani_group => @ani_group_2)
      @params = {"0" => {:id => @xref_1.id, :_destroy => '1', :ani_group_id => @ani_group_1.id},
                 "1" => {:id => @xref_2.id, :_destroy => 'false', :ani_group_id => @ani_group_2.id},
                 "2" => {:_destroy => '1'}}
    end
    
    describe '#delete_anis' do
      it "should delete any xrefs whose id is passed in the params with :_destroy" do
        @geo_route_group.delete_anis(@params)
        @geo_route_group.reload
        @geo_route_group.geo_route_ani_xrefs.should include(@xref_2)
      end
    end
    
    describe '#saved_anis' do
      it "should find xrefs that do not have ':_destroy'" do
        GeoRouteGroup.saved_anis(@params).should include({"1" => @params["1"]})
      end
      
      it "should not find xrefs that have ':_destroy'" do
        GeoRouteGroup.saved_anis(@params).should_not include({"0" => @params["0"]}, {"2" => @params["2"]})
      end
    end
  end
end
