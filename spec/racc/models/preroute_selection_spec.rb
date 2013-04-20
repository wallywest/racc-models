require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PrerouteSelection do
  
  describe "groups_and_vlabels" do
    it "should return pre-routes selections for the app_id in addition to group or vlabel details" do
      g_category = 'f'
      g_name = 'group_for_preroute_test'
      g_display_name = 'Group for Testing'
      g_position = 3
      v_vlabel = 'Route for Testing'
      v_preroute_group_id = 11
      
      grp = FactoryGirl.create(:group, :category => g_category, :name => g_name, :display_name => g_display_name, :position => g_position)
      vlm = FactoryGirl.create(:vlabel_map, :vlabel => v_vlabel, :preroute_group_id => v_preroute_group_id)
            
      ps_1 = FactoryGirl.create(:preroute_selection, :group => grp)
      ps_2 = FactoryGirl.create(:preroute_selection, :vlabel_map => vlm)
      
      all_ps = PrerouteSelection.groups_and_vlabels(1)
      all_ps[0].group_category.should == g_category
      all_ps[0].group_name.should == g_name
      all_ps[0].group_display_name.should == g_display_name
      all_ps[0].group_position.should == g_position
      all_ps[1].vlabel.should == v_vlabel
      all_ps[1].preroute_group_id.should == v_preroute_group_id
    end
  end
end
