require 'spec_helper'

describe LabelDestinationMap do
  context :validations do
    before do
      @ldm = FactoryGirl.build(:label_destination_map)
    end
    
    it "should be valid" do
      @ldm.should be_valid
    end
    
    it "should be invalid if the app_id is missing" do
      @ldm.app_id = nil
      @ldm.should be_invalid
    end
    
    it "should be invalid if the mapped_destination_id is missing" do
      @ldm.mapped_destination_id = nil
      @ldm.should be_invalid
    end
    
    it "should be invalid if the exit_id is missing" do
      @ldm.exit_id = nil
      @ldm.should be_invalid
    end
    
    it "should be invalid if the exit_type is missing" do
      @ldm.exit_type = nil
      @ldm.should be_invalid
    end

    it "should be valid if the vlabel_map_id is missing" do
      @ldm.vlabel_map_id = nil
      @ldm.should be_valid
    end
  end

  describe :routed_to, slow: true do
    it "scopes to the given type" do
      FactoryGirl.create(:label_destination_map, exit_type: "Destination")
      FactoryGirl.create(:label_destination_map, exit_type: "VlabelMap")
      LabelDestinationMap.routed_to("Destination").should have(1).item
    end
  end
end
