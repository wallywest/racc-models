require File.dirname(__FILE__) + '/../spec_helper'

describe Setting do

  before(:each) do
    @company = FactoryGirl.create(:company)
  end
  
  it 'should be stored in the racc_nvp table' do
    Setting.table_name.should eql('racc_nvp')
  end

  it 'should belong to a company' do

    setting1 = FactoryGirl.create(:setting)
    @company.settings << setting1
    setting1.reload
    setting1.company.should eql(@company)
  end
  
  it "should have a compnay with 2 settings when two relationships are created" do
    setting1 = FactoryGirl.create(:setting)
    @company.settings << setting1
    setting1.reload
    setting1.company.should eql(@company)
    
    setting2 = FactoryGirl.create(:setting, :name => 'test_setting_2')
    @company.settings << setting2
    setting2.reload
    setting2.company.should eql(@company)
    
    @company.settings.length.should eql(2)
  end

  it 'should update the racc_company modified_time_unix attribute after save' do
  
    @now = Time.now
    setting1time = @now
    Time.stub!(:now).and_return(setting1time)
  
    setting1 = FactoryGirl.create(:setting)
    @company.settings << setting1
  
    @company.reload
    @company.company_config.modified_time_unix.should == @now.to_i
  
    setting2time = @now + 60
    Time.stub!(:now).and_return(setting2time)
    
    setting2 = FactoryGirl.create(:setting, :name => 'test_setting_2')
    @company.settings << setting2
      
    @company.reload
    @company.company_config.modified_time_unix.should_not == setting2time
  
  end
  
  it 'should update the racc_companie modified_time_unix attribute after destroy' do
  
    @now = Time.now
    setting1time = @now
    Time.stub!(:now).and_return(setting1time)
  
    setting1 = FactoryGirl.create(:setting)
    @company.settings << setting1
    
  
    @company.reload
    @company.company_config.modified_time_unix.should == setting1time.to_i
  
    setting1destroy = @now + 120
    Time.stub!(:now).and_return(setting1destroy)
  
    setting1.destroy
  
    @company.reload
    @company.company_config.modified_time_unix.should == setting1destroy.to_i
  end
end
