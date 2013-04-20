require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CompanyJobId do
  
  describe "validation" do

    before(:each) do
      @company_job_id = FactoryGirl.create(:company_job_id)
    end
    
    it "should not allow job ids shorter than 3 digits" do
      @company_job_id.job_id = 12
      @company_job_id.should_not be_valid
      
    end
    
    it "should not allow job ids longer than 5 digits" do
      @company_job_id.job_id = 123456
      @company_job_id.should_not be_valid
    end
    
    it "should allow job ids of 3-5 digits" do
      @company_job_id.job_id = rand(99899) + 100
      @company_job_id.should be_valid
    end
    
    it "should only allow job ids that are numeric" do
      @company_job_id.job_id = 'abc'
      @company_job_id.should_not be_valid
    end
    
    it "should always have a company id" do
      @company_job_id.company_id = nil
      @company_job_id.should_not be_valid
    end
    
  end
  
end
