require 'spec_helper'

describe Dli do
  describe "Validating DLI" do
    before do
      @li = FactoryGirl.build(:li, :dpct => 100)
      @dli = FactoryGirl.build(:dli, :lis => [@li])
    end
  
    it "should be valid" do
      @dli.should be_valid
    end
  
    it "should be invalid if a dli with the same name already exists" do
      @dli_two = Dli.new
      @dli_two.app_id = 1
      @dli_two.description = "testing"
      @dli_two.value = @dli.value
      @dli_two.should_not be_valid
    end
  
    it "should be invalid if the value is longer than 64 characters" do
      s = ""
      65.times do
        s += "s"
      end
      @dli.value = s
      @dli.should_not be_valid
    end
    
    it 'should be invalid if there are more than 50 LIs assigned' do
      51.times do |i|
        @dli.lis << Li.new
      end
      @dli.should_not be_valid
    end
  
    it "should be invalid if the value has an invalid character" do
      @dli.value = "hello!@#"
      @dli.should_not be_valid
    end
  
    it "should be valid if the value has a dash, space, or underscore" do
      @dli.value = "hello_test of-tests"
      @dli.should be_valid
    end
  
    it "should be invalid if the description is longer than 64 characters" do
      s = ""
      65.times do
        s += "s"
      end
      @dli.description = s
      @dli.should_not be_valid
    end
  
    it "should be valid if the description has a dash, space, underscore, comma, or apostrophe" do
      @dli.description = "hello, there you_test of-test's"
      @dli.should be_valid
    end
  
    it "should find LIs" do
      @dli.lis[0].should == @li
    end
    
    it "is valid if trunks total 100" do
      @dli.should be_valid
    end
    
    it "is invalid if trunks total to less than 100" do
      @li.dpct = 99
      @dli.should_not be_valid
    end
    
    it "is invalid if trunks total to more than 100" do
      @li.dpct = 101
      @dli.should_not be_valid
    end
    
    it "is invalid if no LIs are assigned" do
      @dli.lis = []
      @dli.should_not be_valid
    end
    
    it "adds the totals of 2 LIs" do
      lis = [FactoryGirl.build(:li, :dpct => 30), FactoryGirl.build(:li, :dpct => 70)]
      @dli.lis = lis
      @dli.should be_valid
    end
    
    it "is able to handle nils in the lis' dpct field (such as when the field is left blank)" do
      lis = [FactoryGirl.build(:li, :dpct => nil), FactoryGirl.build(:li, :dpct => 70)]
      @dli.lis = lis
      @dli.should_not be_valid
    end
    
    it "it not valid if a dpct is nil" do
      lis = [FactoryGirl.build(:li, :dpct => 100), FactoryGirl.build(:li, :dpct => nil)]
      @dli.lis = lis
      @dli.should_not be_valid
    end
  end
  
end
