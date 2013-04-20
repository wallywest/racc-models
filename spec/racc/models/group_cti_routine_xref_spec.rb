require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GroupCtiRoutineXref do
  
  describe "validations" do
    before(:each) do
      @cti_routine_id = 3
      @group_id = 45
      @group_cti_routine_xref = FactoryGirl.build(:group_cti_routine_xref, :cti_routine_id => @cti_routine_id, :group_id => @group_id)
    end
    
    it "is valid" do
      @group_cti_routine_xref.should be_valid
    end
    
    it "is not valid if the cti routine is not unique within the group" do
      FactoryGirl.create(:group_cti_routine_xref, :group_id => @group_id, :cti_routine_id => @cti_routine_id)
      @group_cti_routine_xref.should_not be_valid
    end
    
    it "is valid if the cti routine is the same, but in another group" do
      FactoryGirl.create(:group_cti_routine_xref, :group_id => 236, :cti_routine_id => @group_cti_routine_xref.id)
      @group_cti_routine_xref.should be_valid      
    end
  end
  
end
