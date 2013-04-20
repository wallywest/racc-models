require File.dirname(__FILE__) + '/../spec_helper'

describe AniGroup do
  describe 'uniqueness_of_anis' do
    before :each do
      @ani_group = FactoryGirl.create(:ani_group)
    end
    
    it 'should allow unique anis' do
      @ani_group.ani_maps << FactoryGirl.create(:ani_map, :ani_group => @ani_group, :ani => '773')
      @ani_group.ani_maps << FactoryGirl.create(:ani_map, :ani_group => @ani_group, :ani => '123')
      @ani_group.valid?.should == true
    end
    
    it 'should not allow duplicate anis' do
      @ani_group.ani_maps << FactoryGirl.create(:ani_map, :ani_group => @ani_group, :ani => '773')
      @ani_group.ani_maps << FactoryGirl.create(:ani_map, :ani_group => @ani_group, :ani => '773')
      @ani_group.valid?.should == false
    end
  end
  
  describe 'uniqueness_across_geo_routes' do
    before :each do
      @geo_route_group = FactoryGirl.create(:geo_route_group)
      @ani_group_1 = FactoryGirl.create(:ani_group)
      @ani_group_2 = FactoryGirl.create(:ani_group)
      
      @xref_1 = FactoryGirl.create(:geo_route_ani_xref, :geo_route_group => @geo_route_group, :ani_group => @ani_group_1)
      @ani_map_1 = FactoryGirl.create(:ani_map, :ani_group => @ani_group_1, :ani => '123')
      
      @xref_2 = FactoryGirl.create(:geo_route_ani_xref, :geo_route_group => @geo_route_group, :ani_group => @ani_group_2)
      @ani_map_2 = FactoryGirl.create(:ani_map, :ani_group => @ani_group_2, :ani => '773')
      
      @ani_group_1.reload
    end
    
    it 'should not allow addition of a conflicting ani in a GeoRoute' do
      ani_map = FactoryGirl.create(:ani_map, :ani_group => @ani_group_1, :ani => '773')
      @ani_group_1.ani_maps << ani_map
      @ani_group_1.valid?.should == false
    end
    
    it 'should allow addition of a unique ani to a GeoRoute' do
      ani_map = FactoryGirl.create(:ani_map, :ani_group => @ani_group_1, :ani => '456')
      @ani_group_1.ani_maps << ani_map
      @ani_group_1.valid?.should == true
    end
  end
end
