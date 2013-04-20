require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DynamicIvrDestination do
  before(:each) do
    FactoryGirl.create(:destination_property)
  end
  
  describe "state_to_enabled" do
    it "should set the tree state to 'Enabled' if there are no more destinations attached to the DIVR" do
      divr_dest = FactoryGirl.create(:dynamic_ivr_destination)
      divr = divr_dest.dynamic_ivr
      divr.reload
      divr.state.should == DynamicIvr::STATE_ACTIVE
      
      divr_dest.destroy
      divr.reload
      divr.state.should == DynamicIvr::STATE_ENABLED
    end
    
    it "should keep the tree state as 'Active' if there are destinations attached to the DIVR" do
      divr_dest_1 = FactoryGirl.create(:dynamic_ivr_destination)
      divr = divr_dest_1.dynamic_ivr
      divr_dest_2 = FactoryGirl.create(:dynamic_ivr_destination, :dynamic_ivr_id => divr.id)

      divr.reload
      divr.state.should == DynamicIvr::STATE_ACTIVE
      
      divr_dest_1.destroy
      divr.reload
      divr.state.should == DynamicIvr::STATE_ACTIVE
    end
  end
  
  describe "update_prev_divr_state" do
    it "should set the previous divr to enabled if a previous divr existed" do
      divr_new = FactoryGirl.create(:dynamic_ivr)
      divr_dest = FactoryGirl.create(:dynamic_ivr_destination)
      divr_old = divr_dest.dynamic_ivr
      
      divr_dest.dynamic_ivr = divr_new
      divr_dest.save

      DynamicIvr.find(divr_old.id).state.should == DynamicIvr::STATE_ENABLED
    end
  end
    
end
