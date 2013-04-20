require 'spec_helper'

describe Slot do
  before(:each) do
    @valid_attributes = {
      :prompt_set_id => 1,
      :enabled => 1,
      :prompt_order => 1,
      :prompt_id => 1,
      :app_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Slot.create!(@valid_attributes)
  end
  
  it "should belong to a PromptSet" do
    @prompt_set = FactoryGirl.create(:prompt_set)
    @slot = FactoryGirl.create(:slot, :prompt_set => @prompt_set)
    
    @slot.prompt_set.should == @prompt_set
    @slot.save
    @prompt_set.reload
    @prompt_set.slots[0].should == @slot
  end
end
