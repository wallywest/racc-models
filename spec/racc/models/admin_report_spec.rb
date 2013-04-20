require 'spec_helper'

describe AdminReport do
  describe "validations" do
    before do
      @report = FactoryGirl.build(:admin_report)
    end

    it "should be valid" do
      @report.should be_valid
    end

    [:app_id, :name, :username, :url].each do |field|
      it "should be invalid if #{field} is blank" do
        @report.send("#{field}=", "")
        @report.should be_invalid
      end
    end

    it "should be invalid if it has the same name as an existing report" do
      name = "report_name"
      FactoryGirl.create(:admin_report, :name => name)
      @report.name = name
      @report.should be_invalid
    end

    it "should be valid if it has the same name as an existing report but in a different app_id" do
      name = "report_name"
      FactoryGirl.create(:admin_report, :name => name, :app_id => @report.app_id + 1)
      @report.name = name
      @report.should be_valid
    end

    context "password fields" do
      it "should allow a blank for existing reports" do
        @report.save
        @report.password = ""
        @report.password_confirmation = ""
        @report.should be_valid
      end

      it "should not allow a blank for the default report" do
        @report.name = AdminReport::DEFAULT_NAME
        @report.password = ""
        @report.password_confirmation = ""
        @report.save
        @report.password = ""
        @report.password_confirmation = ""
        @report.should be_invalid
      end
  
      it "should not allow a blank for new reports" do
        @report.password = ""
        @report.password_confirmation = ""
        @report.should be_invalid
      end
  
      it "should be invalid if the confirmation doesn't match" do
        @report.password_confirmation = @report.password + "extra_chars"
        @report.should be_invalid
      end
    end

    context "for default reports" do
      let(:report_attrs) { {:name => AdminReport::DEFAULT_NAME, :username => nil, :password => nil, :password_confirmation => nil, :url => nil} }

      it "should be valid when creating with blank fields" do
        FactoryGirl.create(:admin_report, report_attrs)
      end

      it "should be invalid when updating with blank fields" do
        @report.save
        @report.attributes = report_attrs
        @report.should be_invalid
      end
    end
  end

  describe "has_blank_default?" do
    let(:report){ FactoryGirl.build(:admin_report, :id => 123) }

    context "with blank fields" do
      let(:blank_report){ FactoryGirl.build(:admin_report, :username => nil, :password => nil, :url => nil) }
      subject{ blank_report.has_blank_default? }

      it "should return true if the report is a default" do
        blank_report.stub!(:is_default?).and_return true
        should be_true
      end

      it "should return false if the report is not a default" do
        blank_report.stub!(:is_default?).and_return false
        should be_false
      end
    end

    context "with populated fields" do
      subject{ report.has_blank_default? }

      it "should return false if the report is a default" do
        report.stub!(:is_default?).and_return true
        should be_false
      end
      it "should return false if the report is not a default" do
        report.stub!(:is_default?).and_return false
        should be_false
      end
    end
  end

  describe "determine_password" do
    let(:orig_pwd){ "orig_pwd" }
    let(:new_pwd){ "new_pwd" }
    let(:report){ FactoryGirl.build(:admin_report, :password => orig_pwd, :password_confirmation => orig_pwd) }
    subject{ report.send(:determine_password) }
    
    it "should allow new password to be saved if it is not blank" do
      report.save
      report.reload
      report.password.should == orig_pwd
      
      report.password = new_pwd
      report.password_confirmation = new_pwd
      report.save
      report.reload
      report.password.should == new_pwd
    end

    it "should not save the new password if it is blank and being updated" do
      report.save
      report.reload
      report.password.should == orig_pwd

      report.password = ""
      report.password_confirmation = ""
      report.save
      report.reload
      report.password.should == orig_pwd
    end
  end

end 
