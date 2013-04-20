require 'spec_helper'

describe Group do
  
  describe "validations" do
    
    before(:each) do
      @group = FactoryGirl.build(:group)
    end

    it "should be valid" do
      @group.should be_valid
    end
    
    it "should be invalid if the name has any characters except letters, numbers, and underscores" do
      @group.name = 'hello there'
      @group.should_not be_valid
      
      @group.name = '@#232_hi'
      @group.should_not be_valid
      
      @group.name = 'passable_name'
      @group.should be_valid
    end
    
    it "should be invalid if there is no name" do
      @group.name = ''
      @group.should_not be_valid
    end
    
    it "should be invalid if a group with the same name exists in the same app_id" do
      @group_two = FactoryGirl.create(:group, :name => 'same_name')
      @group.name = 'same_name'
      @group.should_not be_valid
    end
    
    it "should be valid if a group with the same name exists in another app_id" do
      @group_two = FactoryGirl.create(:group, :name => 'same_name', :app_id => 3)
      @group.name = 'same_name'
      @group.should be_valid      
    end
    
    it "should be invalid if there is no operation id" do
      @group.operation_id = ''
      @group.should_not be_valid
    end
    
    it "should be invalid if the show_display_name is true and display_name is over 20 characters" do
      @group.show_display_name = true
      @group.display_name = 'abcdefghijklmnopqrstu'
      @group.should_not be_valid
    end
    
    it "should be valid if the show_display_name is false and the display_name is oer 20 chars" do
      @group.show_display_name = false
      @group.display_name = 'abcdefghijklmnopqrstu'
      @group.should be_valid
    end
    
    it "should be valid if the display_name is over 20 chars, the show_display_name is true, and it is a default group" do
      @group.group_default = true
      @group.show_display_name = true
      @group.display_name = 'abcdefghijklmnopqrstu'
      @group.should be_valid
    end
    
    it "should be valid if the display_name is nil" do
      @group.display_name = nil
      @group.should be_valid
    end
    
    it "should be valid if the display_name is blank" do
      @group.display_name = ''
      @group.should be_valid
    end
    
    it "should be invalid if the display_name is blank and the show_display_name is true" do
      @group.display_name = ''
      @group.show_display_name = true
      @group.should_not be_valid
    end
    
    context "cti routines" do
      it "should be invalid if the cti routine ids are blank" do
        @group.cti_routine_ids = []
        @group.should_not be_valid
      end
    
      it "should be valid if the cti routine ids are blank for a default group" do
        @group.cti_routine_ids = []
        @group.group_default = true
        @group.should be_valid
      end
    end
    
    context "overrides" do
      it "should be invalid if the override mode is turned on, but an override route is not set" do
        @group.override_mode = "on"
        @group.override_route = ""
        @group.should_not be_valid
        
        @group.override_route = nil
        @group.should_not be_valid
      end

      it "should be valid if the override mode is turned off and an override route is not set" do
        @group.override_mode = "off"
        @group.override_route = ""
        @group.should be_valid
      end
      
      it "should be valid if the override mode is turned on and an override route is set" do
        @group.override_mode = "on"
        @group.override_route = "any override"
        @group.should be_valid        
      end
      
      it "should be valid if the override mode is turned off and an override route is set" do
        @group.override_mode = "off"
        @group.override_route = "any override"
        @group.should be_valid        
      end
    end
    
    context "default routes" do
      before(:each) do
        @group.category = 'f'
      end

      it "should be valid if All is selected" do
        @group.default_routes_filter = Group::DEFAULT_ROUTE_FILTER_ALL
        @group.should be_valid
      end
      
      it "should be valid if Limited is selected and default routes are selected" do
        @group.default_routes_filter = Group::DEFAULT_ROUTE_FILTER_LIMIT
        @group.default_routes << FactoryGirl.create(:vlabel_map)
        @group.should be_valid
      end
      
      it "should not be valid if Limited is selected and no default routes are selected" do
        @group.default_routes_filter = Group::DEFAULT_ROUTE_FILTER_LIMIT
        @group.should_not be_valid
      end
      
      it "should be valid if New is selected and default routes are selected" do
        @group.default_routes_filter = Group::DEFAULT_ROUTE_FILTER_LIMIT_AND_NEW
        @group.default_routes << FactoryGirl.create(:vlabel_map)
        @group.should be_valid
      end
      
      it "should be valid if New is selected and no default routes are selected" do
        @group.default_routes_filter = Group::DEFAULT_ROUTE_FILTER_LIMIT_AND_NEW
        @group.should be_valid
      end
    end
  end
  
  describe "vlabel_maps" do
    
    it "finds all vlabel_maps whose vlabel_group is the name of the group" do
      @group = FactoryGirl.create(:group)
      @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name)
      
      @group.vlabel_maps.should == [@vlabel_map]
    end
    
    it "finds all vlabel_maps whose vlabel_group is the name of the group's geo_route twin group'" do
      @group = FactoryGirl.create(:group)
      @geo_sub_group = FactoryGirl.create(:group, :name => "#{@group.name}_GEO_ROUTE_SUB")
      @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @geo_sub_group.name)
      
      @group.vlabel_maps.should == [@vlabel_map]
    end
    
    it "ignores other vlabel_maps" do
      @group = FactoryGirl.create(:group)
      @group2 = FactoryGirl.create(:group)
      @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => @group2.name)
      
      @group.vlabel_maps.should == []
    end
    
  end

  describe "#name_for_display" do

    it "should show the group's name if no custom label is entered in the display_name attribute" do
      group = FactoryGirl.build(:group, :name => 'base_name')
      group.name_for_display.should == 'base_name'
    end

    it "should show the display_name attribute if it exists and the group is displayed" do
      group = FactoryGirl.build(:group, :name => 'base_name', :display_name => 'display_name', :show_display_name => true)
      group.name_for_display.should == 'display_name'
    end

    it "should show the display name even when the group is not displayed" do
      group = FactoryGirl.build(:group, :name => 'base_name', :display_name => 'display_name', :show_display_name => false)
      group.name_for_display.should == 'display_name'
    end

    it "should show the base name if the group is displayed is true but no display_name is set" do
      group = FactoryGirl.build(:group, :name => 'base_name', :show_display_name => false)
      group.name_for_display.should == 'base_name'
    end
    
    it "should show the base name if the display name is blank" do
      group = FactoryGirl.build(:group, :name => 'base_name', :display_name => '', :show_display_name => true)
      group.name_for_display.should == 'base_name'
    end
    
  end
  
  describe "#name_for_display_on_index" do
    
    it "should say that there is no display name if the display_name is nil" do
      group = FactoryGirl.create(:group, :name => 'base_name', :show_display_name => false)
      group.name_for_display_on_index.should == 'No display name for base_name'
    end
    
    it "should say that there is no display name if the display_name is blank" do
      group = FactoryGirl.create(:group, :name => 'base_name', :show_display_name => false, :display_name => '')
      group.name_for_display_on_index.should == 'No display name for base_name'
    end
    
    it "should return the display name even though the group is not displayed" do
      group = FactoryGirl.create(:group, :name => 'base_name', :show_display_name => false, :display_name => 'display_name')
      group.name_for_display_on_index.should == 'display_name'
    end
    
    it "should return the display name if the group is displayed" do
      group = FactoryGirl.create(:group, :name => 'base_name', :show_display_name => true, :display_name => 'display_name')
      group.name_for_display_on_index.should == 'display_name'
    end
    
  end

  #Don't forget to fix it!
  describe "Group#find_backend_number_group" do
    it "should find the group in the collection whose category is 'b'" do
      app_id = 12345
      Group.should_receive(:find_by_category).with('b', :conditions => ["app_id = ? AND group_default = ?", app_id, false])
      Group.find_backend_number_group app_id
    end
  end

  describe "Group#find_translation_route_group" do
    it "should find the group in the collection whose category is 'x'" do
      app_id = 12345
      Group.should_receive(:find_by_category).with('x', :conditions => ["app_id = ? AND group_default = ?", app_id, false])
      Group.find_translation_route_group app_id
    end
  end

  describe "recent_vlabel_maps" do

    it "should return the most recent vlabel maps for the group" do
      group = FactoryGirl.create(:group, :name => 'test_group', :app_id => 1)
      group2 = FactoryGirl.create(:group, :name => 'another_group', :app_id => 2)
      v1 = FactoryGirl.create(:vlabel_map, :vlabel_group => group.name, :app_id => group.app_id)
      v2 = FactoryGirl.create(:vlabel_map, :vlabel_group => group.name, :app_id => group.app_id)
      v3 = FactoryGirl.create(:vlabel_map, :vlabel_group => group2.name, :app_id => group2.app_id)

      group.recent_vlabel_maps(100).include?(v1).should == true
      group.recent_vlabel_maps(100).include?(v2).should == true
      group.recent_vlabel_maps(100).include?(v3).should == false
      group2.recent_vlabel_maps(100).should == [v3]
    end

  end
  
  describe "vlabel_maps_with_packages" do
    
    before(:each) do
      @group = FactoryGirl.create(:group, :name => 'test_group', :app_id => 1)
      @group2 = FactoryGirl.create(:group, :name => 'another_group', :app_id => 2)
      10.times do |index|
        FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :app_id => @group.app_id)
      end
      FactoryGirl.create(:vlabel_map, :vlabel_group => @group2.name, :app_id => @group2.app_id)
    end
    
    it "should return the most recent vlabel maps for the group if a limit is set" do
      @group.vlabel_maps_with_packages(5).size.should == 5
    end
    
    it "should return all of the vlabel maps for the group if a limit is not set" do
      @group.vlabel_maps_with_packages.size.should == 10
    end
    
    it "should only find vlabel maps in the current app_id" do
      @group2.vlabel_maps_with_packages.size.should == 1
    end
    
  end
  
  # describe "audit_preroute_group" do
  #  
  #   before(:each) do
  #     @group = FactoryGirl.create(:group, :app_id => 1)
  #     @user_login = 'racc_test'
  #     @app_id = 1
  #   end
  # 
  #   it "should create an audit for the preroute group change for the group" do
  #     FactoryGirl.create(:destination_property)
  #     @destination = FactoryGirl.create(:destination)
  #     preroute_group = FactoryGirl.create(:preroute_group, :app_id => 1, :destination => @destination.destination)
  #     
  #     @group.audit_preroute_group(preroute_group.id, @user_login, @app_id)
  #     mock_preroute_audit(preroute_group.group_name)
  #   end
  #   
  #   it "should create an audit for the preroute group when nil is chosen" do
  #     @group.audit_preroute_group(nil, @user_login, @app_id)
  #     mock_preroute_audit('None in use')
  #   end
  #   
  #   def mock_preroute_audit(preroute_group_name)
  #     most_recent_audit = Audit.last
  #     most_recent_audit.auditable_type.should == 'Group'
  #     most_recent_audit.auditable_id.should == @group.id
  #     most_recent_audit.action.should == 'update'
  #     most_recent_audit.app_id.should == @app_id
  #     most_recent_audit.changes.should == {:preroute_group => preroute_group_name}
  #   end
  # 
  # end
  
  describe "preroute_group_changed?" do

    before(:each) do
      @group = FactoryGirl.create(:group)
      @vlabel_map = FactoryGirl.create(:vlabel_map, :app_id => @group.app_id, :vlabel_group => @group.name, :preroute_group_id => 1)
    end
    
    it "should return true when the pre-route group has changed for a group" do
      @group.preroute_group_changed?(2).should == true
    end
    
    it "should return false when the pre-route group hasn't changed for a group" do
      @group.preroute_group_changed?(1).should == false
    end
    
    it "should return false if there are no vlabel_maps for the group" do
      no_vlm_group = FactoryGirl.create(:group, :app_id => 2, :name => 'no_vlm_group_name')
      no_vlm_group.preroute_group_changed?(nil).should == false
    end
    
    it "should return true if nil is being compared to ''" do
      @vlabel_map.preroute_group_id = nil
      @vlabel_map.save
      @group.preroute_group_changed?('').should == false
    end
    
  end
  
  describe "#copy_group_and_operation" do

    before(:each) do
      # !!NOTE!!: With the current version of rspec (2.5.0), the valid call is invalid on the 
      # cloned group if the display_name is not originally on the group.  When debugging the
      # code, the display name was present on the cloned group, but the valid? call insisted
      # that it was not present.  This works fine in the web app, this just fails in the specs.
      # Hopefully the next version of rspec will not have this issue.
      @group = FactoryGirl.create(:group, :display_name => "temp soln")
      @new_group_attrs = {:name => 'new_group_name', :display_name => 'new display name', :show_display_name => true}
    end
    
    it "should make a copy of the group with a name that gets passed in" do
      new_group = @group.copy_group_and_operation(@new_group_attrs)

      new_group.should be_valid
      new_group.name.should == @new_group_attrs[:name]
    end
    
    it "should also make a clone of the operation" do
      new_group = @group.copy_group_and_operation(@new_group_attrs)

      new_op = new_group.operation
      new_op.should be_valid
      new_op.vlabel_group.should == @new_group_attrs[:name]
    end
    
    it "should return an invalid new group if the group or operation was not created" do
      new_group = @group.copy_group_and_operation({:name => ''})
      new_group.should_not be_valid
    end
    
    it "should create a CTI Routine of 0 after the group is copied" do
      new_group = @group.copy_group_and_operation(@new_group_attrs)
      group_cti_routines = new_group.cti_routines
      group_cti_routines.size.should == 1
      group_cti_routines[0].value.should == 0
      new_group.default_cti_routine_record.value.should == 0
    end
        
  end
  
  describe "#category_for_display" do
    
    it "should return the category name for f groups" do
      group = FactoryGirl.create(:group, :category => 'f')
      group.category_for_display.should == 'Front End'
    end
    
    it "should return the category name for b groups" do
      group = FactoryGirl.create(:group, :category => 'b')
      group.category_for_display.should == 'Back End'
    end
    
    it "should return the category name for x groups" do
      group = FactoryGirl.create(:group, :category => 'x')
      group.category_for_display.should == 'Back End'
    end
    
    it "returns unknown if no group type match is found" do
      group = FactoryGirl.create(:group, :category => 'kfweihwqoih')
      group.category_for_display.should == 'Unknown Group Type'
    end
    
  end
  
  describe "individual_mode?" do
    
    it "should return true if the operation is not 11" do
      group = FactoryGirl.build(:group, :operation => FactoryGirl.create(:operation, :operation => 6))
      group.individual_mode?.should == true
    end
    
    it "should return false if the operaiton is 11" do
      group = FactoryGirl.build(:group, :operation => FactoryGirl.create(:operation, :operation => 11))
      group.individual_mode?.should == false
    end
    
  end
  
  describe "disable_operation_field?" do
    
    it "should return true if the group is a b group and has operation 11" do
      group = FactoryGirl.build(:group, :category => 'b', :operation => FactoryGirl.create(:operation, :operation => 11))
      group.disable_operation_field?.should == true
    end
    
    it "should return false if the group is a f group and has operation 11" do
      group = FactoryGirl.build(:group, :category => 'f', :operation => FactoryGirl.create(:operation, :operation => 11))
      group.disable_operation_field?.should == false
    end
    
    it "should return false if the group is a b group and does not have operation 11" do
      group = FactoryGirl.build(:group, :category => 'b', :operation => FactoryGirl.create(:operation, :operation => 6))
      group.disable_operation_field?.should == false
    end
    
    it "should return false if the group is a f group and does not have operation 11" do
      group = FactoryGirl.build(:group, :category => 'f', :operation => FactoryGirl.create(:operation, :operation => 6))
      group.disable_operation_field?.should == false
    end
  end

  describe "can_override?" do
    
    it "should return true if the group has operations 11, 6, or 9" do
      grp = FactoryGirl.build(:group, :category => 'b')
      [11,6,9].each do |op|
        grp.can_override?(op).should == true
      end
    end
    
    it "should return false if the group does not have operations 11, 6, or 9" do
      grp = FactoryGirl.build(:group, :category => 'b')
      [1, 5, 12, 'a', nil].each do |op|
        grp.can_override?(op).should == false
      end      
    end
    
    it "should return false if the group has operations 11, 6, or 9 and is a frontend grp" do
      grp = FactoryGirl.build(:group, :category => 'f')
      [11,6,9].each do |op|
        grp.can_override?(op).should == false
      end
    end
    
  end
  
  describe "update_default_cti_routine" do
    
    context "as a super user" do
      before(:each) do
        @current_user = mock(:current_user)
        @current_user.should_receive(:member_of?).with('Super User').and_return true
      end
      
      it "should update the group's default cti routine" do
        group = FactoryGirl.create(:group)
        cti_routine = FactoryGirl.create(:cti_routine)
        group.cti_routines << cti_routine
      
        @current_user.should_receive(:login)
        group.update_default_cti_routine(cti_routine.id, @current_user).should == true
        group.default_cti_routine_id.should == cti_routine.id
      end
      
      it "should not update the group's default cti routine if it's a default group" do
        group = FactoryGirl.create(:group)
        group.group_default = true
        group.update_default_cti_routine(0, @current_user).should == true
        GroupCtiRoutineXref.should_not_receive(:update_all).with(any_args)
      end
    
    end
    
    context "as a non-super user" do
      before(:each) do
        @current_user = mock(:current_user)
        @current_user.should_receive(:member_of?).with('Super User').and_return false
      end
      
      it "should return true if a super user is not logged in" do
        group = FactoryGirl.build(:group)
        group.update_default_cti_routine(nil, @current_user).should == true
      end
    end 
  end
  
  describe "destroying a group" do
    it "destroys the operation when a group is destroyed" do
      @group = FactoryGirl.create(:group)
      group_id = @group.id
      operation_id = @group.operation.id
      
      @group.destroy
      
      Group.find_by_id(group_id).should == nil
      Operation.find_by_op_id(operation_id).should == nil
    end
  end
  
  describe "used_cti_routine_ids" do
    it "returns cti routine ids that are used by the current group's vlabel maps" do
      app_id = 3
      group = FactoryGirl.create(:group, :name => "grpone", :app_id => app_id)
      group2 = FactoryGirl.create(:group, :name => "grptwo", :app_id => app_id)
      cti_routine = FactoryGirl.create(:cti_routine, :app_id => app_id)
      cti_routine2 = FactoryGirl.create(:cti_routine, :app_id => app_id)
      vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel_group => group.name, :app_id => app_id, :cti_routine => cti_routine.value)
      vlabel_map2 = FactoryGirl.create(:vlabel_map, :vlabel_group => group2.name, :app_id => app_id, :cti_routine => cti_routine2.value)

      group.used_cti_routine_ids.should == [cti_routine.id]
      group2.used_cti_routine_ids.should == [cti_routine2.id]
    end
  end
  
  describe "has_mapped_dnises?" do
    before(:each) do
      @group = FactoryGirl.create(:group)
    end
    
    it "returns true if there are mapped dnises in the group" do
      FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :mapped_dnis => 12345)
      @group.has_mapped_dnises?.should == true
    end
    
    it "returns false if there are mapped dnises in the same group, but in the wrong app_id" do
      @another_group = FactoryGirl.create(:group, :app_id => 13, :name => @group.name)
      FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :app_id => @another_group.app_id, :mapped_dnis => 12345)
      
      @group.has_mapped_dnises?.should == false
    end
    
    it "returns false if there are no mapped dnises in the group" do
      FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :mapped_dnis => nil)      
      FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :mapped_dnis => '')
      
      @group.has_mapped_dnises?.should == false
    end
  end
  
  describe "display_cti_routine_field?" do
    before(:each) do
      @group = FactoryGirl.create(:group)
    end
    
    it "returns true if there are many cti routines available for the group" do
      @group.cti_routines = [FactoryGirl.create(:cti_routine, :value => 0), FactoryGirl.create(:cti_routine, :value => 1)]
      
      @group.display_cti_routine_field?.should == true
    end
    
    it "returns true if there is one cti routine for the group and it is NOT 0" do
      @group.cti_routines = [FactoryGirl.create(:cti_routine, :value => 2)]
      @group.display_cti_routine_field?.should == true
    end
    
    it "returns false if there is one cti routine for the group and it is 0" do
      @group.cti_routines = [FactoryGirl.create(:cti_routine, :value => 0)]
      @group.display_cti_routine_field?.should == false      
    end
  end
  
  describe "vlabels_in_use" do
    before(:each) do
      @group = FactoryGirl.build(:group)
    end
    
    context "one-to-one groups" do
      before(:each) do
        @group.category = 'b'
      end
      
      it "should store the vlabels used in transfer maps" do
        @group.vlabels_in_use.should include :transfer_map
      end
      
      it "should store the vlabels used in geo-routes" do
        @group.vlabels_in_use.should include :geo_route
      end

			it "should store the vlabels used in dequeue labels" do
				@group.vlabels_in_use.should include :dequeue_label
			end
    end
    
    context "many-to-one groups" do
      it "should store the vlabels used as default routes" do
        @group.category = 'f'
        @group.vlabels_in_use.should include :default_f
      end
    end
  end
  
end
