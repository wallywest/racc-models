require 'spec_helper'

describe User do
  describe 'validations' do
    it "rejects a login longer than 12 characters" do
      @user = FactoryGirl.build(:user, :login => "testlongname")
      @user.should be_valid
      @user.login = "testlongname1"
      @user.should_not be_valid
    end
    
    it "rejects a first name longer than 12 characters" do
      @user = FactoryGirl.build(:user, :login => "testlongname")
      @user.should be_valid
      @user.first_name = "testlongname1"
      @user.should_not be_valid
    end
    
    it "rejects a last name longer than 24 characters" do
      @user = FactoryGirl.build(:user, :last_name => "testlongnametestlongname")
      @user.should be_valid
      @user.last_name = "testlongnametestlongname1"
      @user.should_not be_valid
    end
    
    it "rejects non-alphabetic characters in first names" do
      @user = FactoryGirl.build(:user, :first_name => "Frank")
      @user.first_name = "Frank427&_"
      @user.should_not be_valid
    end
    
    it "rejects non-alphabetic characters in last names" do
      @user = FactoryGirl.build(:user, :last_name => "Frank")
      @user.last_name = "Frank427&_"
      @user.should_not be_valid
    end
        
    context "for passwords" do
      before(:each) do
        @user = FactoryGirl.build(:user)
      end
      
      it "should be valid" do
        pwd = "aBcDeFgH1!"
        @user.password = pwd
        @user.password_confirmation = pwd
        @user.should be_valid
      end
      
      it "should be invalid if the password is less than 8 characters" do
        pwd = "aB3$"
        @user.password = pwd
        @user.password_confirmation = pwd
        @user.should_not be_valid
      end
      
      it "should be invalid if the password is more than 40 characters" do
        pwd = "aB3%"
        37.times{ pwd << 'a' }
        
        @user.password = pwd
        @user.password_confirmation = pwd
        @user.should_not be_valid
      end
      
      it "should be invalid if the password does not contain an uppercase letter, lowercase letter, number, and special character" do
        [ 'aaaaaaaa', 'AAAAAAAA', '11111111', '$$$$$$$$',
          'aAaAaAaA', 'a1a1a1a1', 'a$a$a$a$',
          'A1A1A1A1', 'A$A$A$A$', '1$1$1$1$',
          'aA1aA1aA', 'aA$aA$aA', 'A1$A1$A1'].each do |pwd|
          @user.password = pwd
          @user.password_confirmation = pwd
          @user.should_not be_valid
        end
      end
    end
  end
  
  describe "callbacks" do
    describe "before_destroy" do
      it "should delete all associations to groups" do
        @user = FactoryGirl.create(:user)
        
        UserGroupsUsers.should_receive(:delete_all).with(["user_id = ?", @user.id])
        @user.destroy
      end
    end
  end
  
  describe 'deliver_password_reset_instructions' do
    before do
      @user = FactoryGirl.build(:user)
    end
    
    it 'should return true if email delivery succeeds' do
      PasswordMailer.stub_chain(:password_reset_instructions, :deliver)
      @user.deliver_password_reset_instructions.should == true
    end
    
    it 'should return false if email delivery fails' do
      PasswordMailer.stub_chain(:password_reset_instructions, :deliver).and_raise StandardError.new
      @user.deliver_password_reset_instructions.should == false
    end
  end
  
  describe 'role?' do
    before do
      @role = FactoryGirl.create(:user_group, :name => 'Test Role')
      @user = FactoryGirl.create(:user, :user_groups => [@role])
    end
    
    context 'when user has the specified role' do
      it 'will accept symbols as an argument' do
        @user.role?(:test_role).should == true
      end
    
      it 'will accept strings as an argument' do
        @user.role?('Test Role').should == true
      end
    end
    
    it 'will return false if the user does not have the specified role' do
      @user.role?(:other_role).should == false
    end
  end

  describe :member_of? do
    before do
      @user = User.new
      @user.user_groups.new(name: "Routing Admin")
    end

    context "when user is assigned the specified role" do
      it { @user.member_of?("Routing Admin").should be_true }
    end

    context "when user is not assigned the specified role" do
      it { @user.member_of?("Super User").should be_false }
    end

    context "when user is not assigned to any role" do
      before do
        @user = User.new
      end

      it { @user.member_of?("Routing Admin").should be_false }
    end
  end

  describe :current_report do
    let(:user){ FactoryGirl.build(:user) }
    
    context "when user is logged into their company" do
      let(:report){ FactoryGirl.build(:admin_report) }
      let!(:company){ FactoryGirl.build(:company, :display_reports => true) }
      subject{ user.current_report(user.app_id) }

      before do
        user.should_receive(:company).and_return company
      end
  
      it "should return 'report_blank_default' if the Default report is blank" do
        user.should_receive(:admin_report).and_return report
        report.should_receive(:has_blank_default?).and_return true
  
        should == "report_blank_default"
      end
  
      it "should return 'report_none' if the user doesn't have a report" do
        user.should_receive(:admin_report).and_return nil
  
        should == "report_none"
      end
  
      it "should return the current user's report" do
        user.should_receive(:admin_report).and_return report
        report.should_receive(:has_blank_default?).and_return false
   
        should == report 
      end

      it "should return 'report_none' if reports are not enabled" do
        company.display_reports = false

        should == "report_none"
      end
    end

    context "when user is logged into another company" do
      subject{ user.current_report(another_app_id) }
      let(:another_app_id){ user.app_id + 1 }

      it "should return the Default report of the other company" do
        another_company = FactoryGirl.build(:company, :display_reports => true)
        report = FactoryGirl.build(:admin_report, :app_id => another_app_id)

        user.should_not_receive(:admin_report)
        user.should_not_receive(:company)
        Company.should_receive(:find).with(another_app_id).and_return another_company
        report.should_receive(:has_blank_default?).and_return false
        another_company.should_receive(:default_admin_report).and_return report

        should == report
      end
    end
  end
end
