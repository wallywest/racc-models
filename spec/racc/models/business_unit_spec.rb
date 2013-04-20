# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BusinessUnit do
  before(:each) do
    @valid_attributes = {
      :name => "Valid_Name",
      :description => false,
      :app_id => 8245
    }
    @bu = FactoryGirl.create(:business_unit)
  end

  it "should create a new instance given valid attributes" do
    BusinessUnit.create!(@valid_attributes)
  end
  
  it "should accept a name with letters, numbers, and underscores" do
    bu = BusinessUnit.new(:name => "VALID_name_1124", :app_id => 8245)
    bu.should be_valid
  end
  
  it "should reject a name with any other characters" do
    bu = BusinessUnit.new(:name  => "Invalid Name")
    bu.should_not be_valid
    
    bu = BusinessUnit.new(:name => "*_wef")
    bu.should_not be_valid
    
    bu = BusinessUnit.new(:name => "(H´∂≈ç¬ø∆")
    bu.should_not be_valid
    
    bu = BusinessUnit.new(:name => "Va+id_Nam$")
  end
  
  it "should validate the presence of the name attribute" do
    @bu = BusinessUnit.new(:description => "Test")
    @bu.valid?.should == false
  end
  
  it "should validate the presence of the app_id attribute" do
    ThreadLocalHelper.thread_local_app_id = nil
    bu = BusinessUnit.new(:name => "Test")
    bu.valid?.should == false
  end
  
  it "should validate that app_id is a number" do
    bu = BusinessUnit.new(:name => "test")
    bu.app_id = "Not a number"
    bu.valid?.should == false
  end
  
  it "should have a unique app_ip + name" do
    bu_name = "SAMPLE_NAME"
    app_id = 1
    bu1 = BusinessUnit.new(:name => bu_name, :app_id => app_id)
    bu1.save
    bu2 = BusinessUnit.new(:name => bu_name, :app_id => app_id)
    bu2.save
    bu2.should_not be_valid
  end
  
  it "should allow duplicate names with different app IDs" do
    bu_name = "SAME_NAME"
    FactoryGirl.create(:business_unit, :name => bu_name, :app_id => 1)
    FactoryGirl.create(:business_unit, :name => bu_name, :app_id => 2)
  end
  
  it "should have many prompt_sets" do
    @bu = FactoryGirl.create(:business_unit, :name => "Consumers", :description => "Consumer business_unit")
    @prompt_sets = [FactoryGirl.create(:prompt_set, :name => "English", :description => "English language prompts"),
                      FactoryGirl.create(:prompt_set, :name => "French", :description => "French language prompts")]
    
    @bu.prompt_sets << @prompt_sets
    
    @bu.prompt_sets.length.should == 2

    @prompt_sets.each do |prompt_set|
      prompt_set.business_unit.should == @bu
    end
      
  end
  
  it "should have many users" do
    @bu = FactoryGirl.create(:business_unit, :name => "Test_ID")
    
    @users = [FactoryGirl.create(:user), FactoryGirl.create(:user, :login => "user", :email => "user@example.com")]
    
    @bu.users << @users
    
    @bu = BusinessUnit.find(@bu.id)
    
    @bu.users.should == @users
  end
    
  describe "#available_prompts" do
    before(:each) do
      @ar = mock(ActiveRecord::Relation)
    end
    
    it "should get the list of permissions (app_id / job_id pairs)" do
      access = BusinessUnitsPrompts.create(:business_unit_id => @bu.id, :recording_app_id => 110, :recording_job_id => 523)
      Prompt.should_receive(:joins).with(any_args).and_return @ar
      @ar.should_receive(:where).with(any_args).and_return([access])
      @bu.available_prompts
    end
    
    it "should query for any prompts matching at least one of the permissions" do
      access = BusinessUnitsPrompts.new(:business_unit_id => @bu.id, :recording_app_id => 110, :recording_job_id => 523)
      access.save
      Prompt.should_receive(:joins).with("INNER JOIN recordings ON recordings.recording_id = prompts.recording_id").and_return @ar
      @ar.should_receive(:where).with('app_id = :app_id AND job_id = :job_id', {:app_id => access.recording_app_id, :job_id => access.recording_job_id}).exactly([access].length).times.and_return([])
      @bu.available_prompts
    end
    
    it "should query for prompts once for each app_id / job_id pair" do
      access = BusinessUnitsPrompts.new(:business_unit_id => @bu.id, :recording_app_id => 110, :recording_job_id => 523)
      access.save
      access2 = BusinessUnitsPrompts.new(:business_unit_id => @bu.id, :recording_app_id => 111, :recording_job_id => 527)
      access2.save
      Prompt.should_receive(:joins).with(any_args).exactly([access, access2].length).times.and_return @ar
      @ar.should_receive(:where).with(any_args).exactly([access, access2].length).times.and_return([])
      @bu.available_prompts
    end
  end
    
end
