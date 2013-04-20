require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DestinationValidationFormat do
  
  describe "validations" do
    before(:each) do
      @dvf = FactoryGirl.build(:destination_validation_format)
    end
    
    it "is valid" do
      @dvf.should be_valid
    end

    it "is not valid if the name is missing" do
      @dvf.name = nil
      @dvf.should_not be_valid
    end
    
    it "is not valid if the regular expression is missing" do
      @dvf.regex = nil
      @dvf.should_not be_valid
    end
    
    it "is not valid if the error message is missing" do
      @dvf.error_message = nil
      @dvf.should_not be_valid
    end
    
    it "is not valid if the description is missing" do
      @dvf.description = nil
      @dvf.should_not be_valid
    end
    
    it "is not valid if the name is not unique" do
      dvf_same = FactoryGirl.create(:destination_validation_format)
      @dvf.name = dvf_same.name
      @dvf.should_not be_valid
    end
    
    it "is not valid if the name is bigger than 64 characters" do
      test_name = ""
      65.times do |n|
        test_name << "t"
      end
      
      @dvf.name = test_name
      @dvf.should_not be_valid
    end
    
    it "is valid if the name is only one character" do
      @dvf.name = 't'
      @dvf.should be_valid
    end
    
    it "is not valid if the name contains characters other than letters, numbers, and underscores" do
      ['test name', '', 'test-name', '!@#$%^&*()'].each do |test_name|
        @dvf.name = test_name
        @dvf.should_not be_valid
      end
    end
    
  end
  
  describe "nbr_destination_properties" do
    it "returns the number of destination properties that the validation is used in" do
      dvf_name = 'test_valid'
      dvf = FactoryGirl.build(:destination_validation_format, :name => dvf_name)
      FactoryGirl.create(:destination_property, :validation_format => dvf_name)
      FactoryGirl.create(:destination_property, :validation_format => dvf_name, :destination_property_name => 'another_dest')
      dvf.nbr_destination_properties.should == 2
    end
    
    it "returns zero if there are no destination properties" do
      dvf = FactoryGirl.build(:destination_validation_format)
      dvf.nbr_destination_properties.should == 0
    end
  end
end
