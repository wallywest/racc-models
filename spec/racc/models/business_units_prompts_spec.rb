require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BusinessUnitsPrompts do
  before(:each) do
    @valid_attributes = {
      :recording_app_id => 1,
      :recording_job_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    BusinessUnitsPrompts.create!(@valid_attributes)
  end
end
