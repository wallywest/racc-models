# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptSet do
  before(:each) do
    @valid_attributes = {
      :name => "Valid_Name",
      :description => false,
      :app_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    PromptSet.create!(@valid_attributes)
  end
  
  it "should accept a name with letters, numbers, and underscores" do
    ps = PromptSet.new(:name => "VALID_name_1124", :app_id => 1)
    ps.should be_valid
  end
  
  it "should reject a name with any other characters" do
    ps = PromptSet.new(:name  => "Invalid Name")
    ps.should_not be_valid
    
    ps = PromptSet.new(:name => "*_wef")
    ps.should_not be_valid
    
    ps = PromptSet.new(:name => "(H´∂≈ç¬ø∆")
    ps.should_not be_valid
    
    ps = PromptSet.new(:name => "Va+id_Nam$")
  end
  
  it "should validate the presence of the name attribute" do
    @ps = PromptSet.new(:description => "Test")
    @ps.valid?.should == false
  end
  
  it "should belong to a category" do
    @business_unit = FactoryGirl.create(:business_unit, :name => "Consumers", :description => "Consumer category")
    @prompt_set = FactoryGirl.create(:prompt_set, :name => "English", :description => "English language prompts")
    
    @prompt_set.business_unit = @business_unit
    @prompt_set.business_unit.name.should == "Consumers"
    @prompt_set.save
    @prompt_set.business_unit.prompt_sets[0].should == @prompt_set
  end
  
  it "should have a unique name per business_unit id" do
    ps1 = PromptSet.new(:name => "PS", :business_unit => @business_unit)
    ps1.save
    ps2 = PromptSet.new(:name => "PS", :business_unit => @business_unit)
    ps2.save
    ps2.should_not be_valid
  end
  
  it "should allow the same name with different business unit ids" do
    ps1 = PromptSet.new(:name => "PS1", :business_unit => @business_unit, :app_id => 1)
    ps1.save
    ps2 = PromptSet.new(:name => "PS1", :business_unit => FactoryGirl.create(:business_unit, :name => "Rnd_name_bu"), :app_id => 1)
    ps2.save
    ps2.should be_valid
  end
  
  it "should have many slots" do
    @prompt_set = FactoryGirl.create(:prompt_set, :name => "English", :description => "English language prompts")
    
    @slots = [FactoryGirl.create(:slot, :prompt_set => @prompt_set, :prompt_order => 1), 
              FactoryGirl.create(:slot, :prompt_set => @prompt_set, :prompt_order => 2)]
              
    @prompt_set.slots << @slots
    @prompt_set.save
    @prompt_set.slots.length.should == 2
  end
  
  it "should return slots sorted by their order attribute" do
    @prompt_set = FactoryGirl.create(:prompt_set)
    @slots = [FactoryGirl.create(:slot, :prompt_order => 5),
              FactoryGirl.create(:slot, :prompt_order => 1),
              FactoryGirl.create(:slot, :prompt_order => 3),
              FactoryGirl.create(:slot, :prompt_order => 7)]
    @prompt_set.slots << @slots
    @prompt_set.save
    
    @prompt_set.slots.map {|s| s.prompt_order}.should == [1, 3, 5, 7]
    
  end
end
