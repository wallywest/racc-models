require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SurveyGroup do
  
  before(:each) do
    @survey_vlabel = "free_form_string"
    ThreadLocalHelper.thread_local_app_id = 1
    @valid_attributes = { :name => 'survey_name', 
                          :description => 'survey desc', 
                          :survey_vlabel => 'free_form_string', 
                          :percent_to_survey => 10, 
                          :dsat_score => 20,
                          :announcement_file => 'survey file',
                          :modified_by => 'test_user',
                          :created_at => Time.now,
                          :updated_at => Time.now}
  end
  
  it "should create a new instance given valid attributes" do
    FactoryGirl.create(:transfer_map, :transfer_string => @survey_vlabel)
    SurveyGroup.create!(@valid_attributes)
  end
  
  it "should not be valid without an app_id" do
    invalid_without(:app_id)
  end
  
  it "should not be valid without a name" do
    invalid_without(:name)
  end
  
  it "should not be valid without a survey_vlabel" do
    invalid_without(:survey_vlabel)
  end
  
  it "should not be valid without a percent_to_survey" do
    invalid_without(:percent_to_survey)
  end
  
  it "should not be valid without a dsat_score" do
    invalid_without(:dsat_score)
  end
  
  it "should not be valid without an announcement_file" do
    invalid_without(:announcement_file)
  end
  
  it "should not be valid without a modified_by" do
    invalid_without(:modified_by)
  end
  
  it "should not be valid if the percent_to_survey is not between 0 and 100" do
    @valid_attributes[:percent_to_survey] = -1
    SurveyGroup.new(@valid_attributes).should_not be_valid
    @valid_attributes[:percent_to_survey] = 101
    SurveyGroup.new(@valid_attributes).should_not be_valid
  end
  
  it "should not be valid if the percent_to_survey is not a number" do
    @valid_attributes[:percent_to_survey] = 'abc'
    SurveyGroup.new(@valid_attributes).should_not be_valid
  end
  
  it "should not be valid if the dsat_score is not a number" do
    @valid_attributes[:dsat_score] = 'abc'
    SurveyGroup.new(@valid_attributes).should_not be_valid    
  end
  
  describe "transfer_string_exists" do
    
    it "verifies that the survey_vlabel attr points to a valid transfer_map" do
      @transfer_map = FactoryGirl.create(:transfer_map, :transfer_string => '3456')
      @survey_group = FactoryGirl.build(:survey_group, :survey_vlabel => '3456')
      
      @survey_group.should be_valid
    end
    
    it "verifies that the survey_vlabel attr points to a valid vlabel_map if it does not match a transfer_map" do
      @vlabel_map = FactoryGirl.create(:vlabel_map, :vlabel => 'vlabel_test')
      @survey_group = FactoryGirl.build(:survey_group, :survey_vlabel => 'vlabel_test')
      
      @survey_group.should be_valid
    end
    
    it "fails if the transfer_string matches nothing" do
      @survey_group = FactoryGirl.build(:survey_group, :survey_vlabel => 'test_it')
      
      @survey_group.should_not be_valid
      @survey_group.errors[:survey_vlabel].should include("must be a valid speed dial or route.")
    end
  end
  
end

def invalid_without(attr)
  @valid_attributes.delete(attr)
  SurveyGroup.new(@valid_attributes).should_not be_valid  
end
