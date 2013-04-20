require File.dirname(__FILE__) + '/../spec_helper'

describe Operation do

  describe "validating" do

    before(:each) do
      @operation = FactoryGirl.create(:operation)
    end

    it "should be valid" do
      @operation.should be_valid
    end

    it "should be invalid if there is no vlabel_group" do
      @operation.vlabel_group = ''
      @operation.should_not be_valid
    end

    it "should be invalid if there is another operation with the same vlabel_group and app_id" do
      @operation_two = FactoryGirl.create(:operation, :vlabel_group => 'same_group')
      @operation.vlabel_group = 'same_group'
      @operation.should_not be_valid
    end

    it "should be valid if there is another opeation with the same vlabel_group in a different app_id" do
      @operation_two = FactoryGirl.create(:operation, :vlabel_group => 'same_group', :app_id => 3)
      @operation.vlabel_group = 'same_group'
      @operation.should be_valid      
    end

  end

  describe "update_newop_on_geo_op" do
    before(:each) do
      @grp_name = "test_group"
      @op = FactoryGirl.create(:operation, :vlabel_group => "#{@grp_name}_GEO_ROUTE_SUB", :operation => Operation::MANY_TO_ONE_GEO_OP, :newop_rec => '')
      @grp = FactoryGirl.create(:group, :name => @grp_name, :operation_id => @op.op_id)
    end
    
    it "should update the newop_rec for the geo-route operation" do
      new_newop_rec = "test_newop_rec"

      @op.newop_rec.should == ''
      Operation.update_newop_on_geo_op(@grp, {:newop_rec => new_newop_rec}, @op.app_id)
      @op.reload
      @op.newop_rec.should == new_newop_rec
    end
    
    it "should not update the newop_rec if it is not updated" do
      @op.newop_rec.should == ''
      Operation.update_newop_on_geo_op(@grp, {}, @op.app_id)
      @op.reload
      @op.newop_rec.should == ''
    end
  end

end
