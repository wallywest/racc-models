require 'spec_helper'

describe "DestinationAttributeBit" do
  
  describe "validations" do
    before(:each) do
      @dest_attr_bit = FactoryGirl.build(:destination_attribute_bit)      
    end
    
    it "should be valid" do
      @dest_attr_bit.should be_valid
    end
    
    it "should be valid if the bit has no description but is not displayed" do
      @dest_attr_bit.description = ""
      @dest_attr_bit.display = false
      
      @dest_attr_bit.should be_valid
    end
    
    it "should not be valid if the bit is displayed with no description" do
      @dest_attr_bit.description = ""
      @dest_attr_bit.display = true
      
      @dest_attr_bit.should be_invalid
    end
  end
  
end
