require 'spec_helper'

describe PrerouteGrouping do
  
  context "validations" do
    before(:each) do
      @preroute_grouping = FactoryGirl.build(:preroute_grouping)
    end
    
    it "should be valid" do
      @preroute_grouping.should be_valid
    end
    
    it "should be invalid if the name is blank" do
      [nil, ''].each do |test_name|
        @preroute_grouping.name = test_name
        @preroute_grouping.should_not be_valid
      end
    end
    
    it "should be invalid if the name exceeds 64 characters" do
      test_name = ""
      65.times {test_name += "n" }
      @preroute_grouping.name = test_name
      @preroute_grouping.should_not be_valid
    end
    
    it "should be invalid if there are no pre-route groups attached" do
      @preroute_grouping.temp_preroute_group_ids = []
      @preroute_grouping.should_not be_valid
    end
    
    context "uniqueness of name" do
      before(:each) do
        @existing_grouping_name = 'Used Grouping'
        @existing_grouping = FactoryGirl.create(:preroute_grouping, :name => @existing_grouping_name, :temp_preroute_group_ids => [FactoryGirl.create(:preroute_group).preroute_group_id])
      end
      
      it "should be invalid if the name is not unique" do
        @preroute_grouping.name = @existing_grouping_name
        @preroute_grouping.should_not be_valid
      end

      it "should be valid if the name is not unique, but in a different app_id" do
        @existing_grouping.update_attributes(:app_id => 2)
        @preroute_grouping.name = @existing_grouping_name
        @preroute_grouping.should be_valid
      end
    end
  end
end
