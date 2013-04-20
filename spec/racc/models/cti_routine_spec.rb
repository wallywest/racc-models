require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CtiRoutine do

  describe "validations" do
    before(:each) do
      @cti_routine = FactoryGirl.build(:cti_routine)
    end
  
    it "is valid" do
      @cti_routine.should be_valid
    end
  
    it "is valid when the value is an integer" do
      [0, 3, 17, 1999, 89900000].each do |int|
        @cti_routine.value = int
        @cti_routine.should be_valid
      end
    end
  
    it "is not valid when the value is not an integer" do
      ['one', 3.4, ''].each do |int|
        @cti_routine.value = int
        @cti_routine.should_not be_valid
      end
    end
  
    it "is not valid when the value is missing" do
      @cti_routine.value = nil
      @cti_routine.should_not be_valid
    end
  
    it "is not valid when the description is missing" do
      @cti_routine.description = nil
      @cti_routine.should_not be_valid
    end

    it "is not valid when the target is missing" do
      @cti_routine.target = nil
      @cti_routine.should_not be_valid
    end

    it "is valid if the target is 'op' or 'destination'" do
      ['op', 'destination'].each do |target|
        @cti_routine.target = target
        @cti_routine.should be_valid
      end
    end

    it "is not valid when the target is not 'op' or 'destination'" do
      @cti_routine.target = 'operation'
      @cti_routine.should_not be_valid
    end
  
    it "is not valid when there is a duplicate value for a company and target" do
      first_cti_routine = FactoryGirl.create(:cti_routine)
      @cti_routine.app_id = first_cti_routine.app_id
      @cti_routine.target = first_cti_routine.target
      @cti_routine.value = first_cti_routine.value
      @cti_routine.should_not be_valid
    end
  
    it "is valid if there is a duplicate value for another company" do
      first_cti_routine = FactoryGirl.create(:cti_routine, :app_id => 2)
      @cti_routine.app_id = 3
      @cti_routine.target = first_cti_routine.target
      @cti_routine.value = first_cti_routine.value
      @cti_routine.should be_valid
    end

    it "is valid if there is a duplicate value for another target" do
      first_cti_routine = FactoryGirl.create(:cti_routine, :target => 'op')
      @cti_routine.app_id = first_cti_routine.app_id
      @cti_routine.target = 'destination'
      @cti_routine.value = first_cti_routine.value
      @cti_routine.should be_valid
    end
  
    it "is not valid if the description is more than 255 characters" do
      invalid_desc = ('0'..'300').to_a.join("")
      @cti_routine.description = invalid_desc
      @cti_routine.should_not be_valid
    end
  
    it "is valid if zero is entered as a value and there already exists a CTI routine of zero" do
      FactoryGirl.create(:cti_routine, :value => 0, :app_id => @cti_routine.app_id)
      @cti_routine.value = 0
      @cti_routine.should_not be_valid
    end  
    
    it "is does not display the 'Value has already been taken' message if a non-numeric value is entered" do
      @cti_routine.value = 'abcd'
      @cti_routine.value_is_char = true
      @cti_routine.should_not be_valid
      @cti_routine.errors.full_messages.each do |err_msg|
        (err_msg =~ /^[Value has already been taken]+$/).should == nil
      end
    end
  end

end
