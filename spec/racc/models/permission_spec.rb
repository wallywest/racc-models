require File.dirname(__FILE__) + '/../spec_helper'

describe Permission do
  # before(:each) do
  #     @permission = Permission.new
  #   end
  # 
  #   it "should be valid" do
  #     @permission.should be_valid
  #   end
  #   
  #   it "should return return a permissions object when rights method is called with valid user id and contorller name" do
  #     @user = User.new
  #     @user.login = "test"
  #     @user.password = "test"
  #     @user.password_confirmation = "test"
  #     @user.first_name = "Test"
  #     @user.last_name = "User"
  #     @user.email = "test@test.com"
  #     @user.save!
  # 
  #     @perm = Permission.new
  #     @perm.p_controller = "exists"
  #     @perm.p_create = "true"
  #     @perm.p_read = "true"
  #     @perm.p_update = "true"
  #     @perm.p_delete = "true"
  #     @user.permissions << @perm
  #     
  #     r = Permission.rights(@user.id, @perm.p_controller)
  #     r.nil?.should be(false)
  #     r.instance_of?(Permission).should be(true)
  #     
  #     # @perm.destroy
  #     # @user.destroy
  #   end
  #   
  #   it "should return nil for rights with no object found" do
  #     @user = User.new
  #     @user.login = "test"
  #     @user.password = "test"
  #     @user.password_confirmation = "test"
  #     @user.first_name = "Test"
  #     @user.last_name = "User"
  #     @user.save
  # 
  #     @perm = Permission.new
  #     @perm.p_controller = "exists"
  #     @perm.p_create = "true"
  #     @perm.p_read = "true"
  #     @perm.p_update = "true"
  #     @perm.p_delete = "true"
  #     @user.permissions << @perm
  # 
  #     Permission.rights(@user.id,"non exisitent").nil?.should be_true
  #     Permission.rights(-1, @perm.p_controller).nil?.should be_true   
    
    # @perm.destroy
    # @user.destroy
  # end
  
  # it "should destroy successfully"
  
end
