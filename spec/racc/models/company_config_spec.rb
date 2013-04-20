require 'spec_helper'

describe CompanyConfig do
  
  before :each do 
    @company = FactoryGirl.create(:company)
    @company_config = @company.company_config
  end
  
  describe "validations" do
    
    describe "valid default_survey values" do
      
      it "should allow any vlabel in the same app id" do
        @vlabel_map = FactoryGirl.create(:vlabel_map, :app_id => 1)
        @company_config.default_survey = @vlabel_map.vlabel
        
        @company_config.should be_valid
      end
      
      it "should not allow a vlabel in another app id" do
        @vlabel_map = FactoryGirl.create(:vlabel_map, :app_id => 2)
        @company_config.default_survey = @vlabel_map.vlabel
        
        @company_config.should_not be_valid
      end
      
      it "should allow a transfer_map in the same app id" do
        @transfer_map = FactoryGirl.create(:transfer_map, :app_id => 1)
        @company_config.default_survey = @transfer_map.transfer_string
        
        @company_config.should be_valid
      end
      
      it "should not allow a transfer map in another app id" do
        @transfer_map = FactoryGirl.create(:transfer_map, :app_id => 2)
        @company_config.default_survey = @transfer_map.transfer_string
        
        @company_config.should_not be_valid
      end
      
      it "should not allow entry of a free form string" do
        @company_config.default_survey = "Free form"
        @company_config.should_not be_valid
      end
      
      it "should allow blanks" do
        @company_config.default_survey = ''
        @company_config.should be_valid
      end
      
      it "should not allow nil" do
        @company_config.default_survey = nil
        @company_config.should_not be_valid
      end
      
    end
    
    describe "valid save_no_xfers_pct" do
      it "should be valid if the save_no_xfers_pct is between 0 and 100" do
        [0, 10, 34, 50].each do |nbr|
          @company_config.save_no_xfers_pct = nbr
          @company_config.should be_valid
        end
      end

      it "should not be valid if the save_no_xfers_pct is under 0 or over 100" do
        [-1, 101, 1000, 1.2, 'abc'].each do |nbr|
          @company_config.save_no_xfers_pct = nbr
          @company_config.should_not be_valid
        end
      end
    end

    describe "valid alt_command_character" do 

      ["1","?"].each do |value|
        it "should not be valid for values #{value}" do
          @company_config.alternate_command_character = value
          @company_config.should_not be_valid
        end
      end

      it "should valid for values A,B,C,D,G" do
        ["A","B","C",""].each do |value|
          @company_config.alternate_command_character = value
          @company_config.should be_valid
        end
      end

    end

    describe "valid input size constraints" do
      before(:each) do 
        @smallstring = "AB"
        @string = "aaaa" * 65
        @bigstring = "aaaaaa" * 256
      end

      it "should not be valid for values larger then 1 for alt_command_character" do
        @company_config.alternate_command_character = @smallstring
        @company_config.should_not be_valid
      end

      it "should not be valid for values larger then 64 for tdd_phone" do
        @company_config.tdd_phone = @string
        @company_config.should_not be_valid
      end

      it "should not be valid for values larger then 64 for tdd_fail_msg" do
        @company_config.tdd_fail_msg = @string
        @company_config.should_not be_valid
      end

      it "should not be valid for values larger then 64 for dce_prompt" do
        @company_config.dce_prompt = @string
        @company_config.should_not be_valid
      end

      it "should not be valid for values larger then 255 for cn_mask" do
        @company_config.cn_mask = @bigstring
        @company_config.should_not be_valid
      end

    end
    
  end
  
  describe "callbacks" do
    
    describe "update_operations" do
      it "should do nothing if the calltype_survey_enabled field is not changed" do
        Operation.should_not_receive(:update_all).with(any_args)
        @company_config.save
      end
      
      it "should do nothing if the calltype_survey_enabled field is not 'T'" do
        @company_config.update_attributes(:calltype_survey_enabled => 'T')
        @company_config.calltype_survey_enabled = 'F'
        Operation.should_not_receive(:update_all).with(any_args)
        @company_config.save
      end
      
      it "should set all operations' post_call field to 'F' if the calltype_survey_enabled field is set to 'T'" do
        @company_config.update_attributes(:calltype_survey_enabled => 'F')
        @company_config.calltype_survey_enabled = 'T'
        Operation.should_receive(:update_all).with(["post_call = ?", 'F'], ["app_id = ?", @company_config.app_id])
        @company_config.save
      end
    end
    
    describe "update_defer_discard" do
      it "updates the defer_discard to 'F' if recording_enabled is 'F'" do
        test_defer_discard('F')
      end
      
      it "does not update the defer_discard if recording_enabled is 'T'" do
        test_defer_discard('T')       
      end
      
      def test_defer_discard(_outcome)
        config = FactoryGirl.build(:company_config, :recording_enabled => _outcome, :defer_discard => 'T')
        config.defer_discard.should == 'T'
        config.valid?
        config.defer_discard.should == _outcome
      end
    end

    describe "update_modified_time_unix" do
      it "updates the modified_time_unix field" do
        now = Time.now
        Time.stub(:now) { now }
        @company_config.save
        @company_config.modified_time_unix.should eq(now.to_i)
      end
    end
        
  end
  
end
