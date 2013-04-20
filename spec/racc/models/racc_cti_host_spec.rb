require 'spec_helper'

describe RaccCtiHost do
  
  context "validations" do
  
    before(:each) do
      @cti_host = FactoryGirl.build(:racc_cti_host)
    end
  
    it "should be valid" do
      @cti_host.should be_valid
    end
    
    it "should be invalid if the name already exists" do
      existing_cti_host = FactoryGirl.create(:racc_cti_host, :cti_name => 'existing_name')
      @cti_host.cti_name = existing_cti_host.cti_name
      @cti_host.should be_invalid
    end
    
    it "should be valid if the name already exists but in a different app_id" do
      existing_cti_host = FactoryGirl.create(:racc_cti_host, :cti_name => 'existing_name', :app_id => @cti_host.app_id.to_i + 1)
      @cti_host.cti_name = existing_cti_host.cti_name
      @cti_host.should be_valid
    end
    
    it "should be invalid if the port is not an integer" do
      ['a', 1.2, '', nil].each do |port|
        @cti_host.port = port
        @cti_host.should be_invalid
      end
    end
  end
end
