require File.dirname(__FILE__) + '/../spec_helper'

describe RecordedDnis do

  describe "validating recorded dnis" do
    
    before(:each) do
      FactoryGirl.create(
        :destination_type, :destination_type => "LI", :gui_value => 1, :platform_value => 1, :display => true, :app_id => 1,
        :regex => "^[\*]$|^[0-9]{10}$", :error_messages => "Destination for LI must contain exactly 10 digits or a single asterisk"
      )
      FactoryGirl.create(
        :destination_type, :destination_type => "DNIS", :gui_value => 2, :platform_value => 2,  :display => true, :app_id => 1,
        :regex => "^[\*]$|^[0-9]{2,9}$", :error_messages => "Destination for DNIS must contain 2-9 digits or a single asterisk"
      )
      FactoryGirl.create(
        :destination_type, :destination_type => "LI+DNIS", :gui_value => 3, :platform_value => 3,  :display => true, :app_id => 1,
        :regex => "[\*]|[0-9]{10}\+[0-9]{2,9}", :error_messages => "Destination for LI+DNIS must contain 10 digits + 2-9 digits or a single asterisk. Example 1234567890+12"
      )
      FactoryGirl.create(
        :destination_type, :destination_type => "DID", :gui_value => 4, :platform_value => 3,  :display => true, :app_id => 1,
        :regex => " ^[*]$|^[0-9]{10}$", :error_messages => "Destination for DID be exactaly 10 digits or a single asterisk"
      )
      FactoryGirl.create(
        :destination_type, :destination_type => "FULL SIP URL", :gui_value => 5, :platform_value => 3,  :display => true, :app_id => 1,
        :regex => "^[\*]$|^sip:\w*@\w*\.[A-Za-z]{3}$", :error_messages => "Destination for Full Sip URL be in the format sip:user@host.com or a single asterisk"
      )
      FactoryGirl.create(
        :destination_type, :destination_type => "SIP USER", :gui_value => 6, :platform_value => 4, :display => true, :app_id => 1,
        :regex => "^[\*]$|^[A-Za-z0-9\.]{1,20}$", :error_messages => "Destination for Sip User be between 1 and 20 digits/letters or a single asterisk"
      )
      FactoryGirl.create(
        :destination_type, :destination_type => "SIP HOST", :gui_value => 7, :platform_value => 5,  :display => true, :app_id => 1,
        :regex => "^[\*]$|^[A-Za-z0-9\.]{1,30}$", :error_messages => "Destination for Sip Host be between 1 and 30 digits/letters or a single asterisk"
      )
      FactoryGirl.create(
        :destination_type, :destination_type => "INTERNATIONAL DID", :gui_value => 8, :platform_value => 3,  :display => true, :app_id => 1,
        :regex => "^[\*]$|^[0-9\+]{1,30}$", :error_messages => "International destinations must be between 1 and 30 digits/letters and can include + or it must be a single asterisk"
      )    
    
      FactoryGirl.create(:company)
      @recorded_dnis = FactoryGirl.create(:recorded_dnis)
      @company = @recorded_dnis.company
    end
  
    it 'should be valid when instantiated via FactoryGirl' do
      @recorded_dnis.should be_valid
    end
  
    it 'should be stored in the racc_cust_parms table' do
      RecordedDnis.table_name.should eql('racc_cust_parms')
    end
  
    it 'should belong to a company' do
      @company.should be_a Company
    end
  
    it 'should allow letters in the parm_name attribute' do
      @recorded_dnis.parm_name = '2354234asfsadf012345678901234567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow underscores in the parm_name attribute' do
      @recorded_dnis.parm_name = '2__354234asfsadf012345678901234567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow dashes in the parm_name attribute' do
      @recorded_dnis.parm_name = '2__354--f012345678901234567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow 40 chars in the parm_name attribute' do
      @recorded_dnis.parm_name = '1234567890123456789012345678901234567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow 41 chars in the parm_name attribute' do
      @recorded_dnis.parm_name = '12345678901234567890123456789012345678901'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow forward-slash(/) in the parm_name attribute' do
      @recorded_dnis.parm_name = '/blah'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow . in the parm_name attribute' do
      @recorded_dnis.parm_name = '.'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should allow 3 digits for parm_key (inbound dnis)' do
      @recorded_dnis.parm_key = '345'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow 10 digits for parm_key (inbound dnis)' do
      @recorded_dnis.parm_key = '1234567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow 11 digits for parm_key (inbound dnis)' do
      @recorded_dnis.parm_key = '12345678901'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow 2 digits for parm_key (inbound dnis)' do
      @recorded_dnis.parm_key = '12'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should allow alpha characters in s1 (call type)' do
      @recorded_dnis.s1 = "TEStinging"
      @recorded_dnis.should be_valid
    end
  
    it 'should allow digits in s1 (call type)' do
      @recorded_dnis.s1 = "TEStingi2142134ng"
      @recorded_dnis.should be_valid
    end
  
    it 'should periods in s1 (call type)' do
      @recorded_dnis.s1 = "TxESting.i.2.1.4.2.134ng"
      @recorded_dnis.should be_valid
    end
  
    it 'should allow dashes in s1 (call type)' do
      @recorded_dnis.s1 = "TESt-in-gi-21-4-2134ng"
      @recorded_dnis.should be_valid
    end
  
    it 'should allow underscores in s1 (call type)' do
      @recorded_dnis.s1 = "TESt-i_n-gi_-21-4-2134ng"
      @recorded_dnis.should be_valid
    end
  
    it 'should allow a single ampersand in s1 (call type)' do
      @recorded_dnis.s1 = "*"
      @recorded_dnis.should be_valid
    end
  
    it "should allow s1 (call type) to have a single character other than *" do
      @recorded_dnis.s1 = "j"
      @recorded_dnis.should be_valid
    end
  
    it "should allow s1 (call type) to have a 60 characters" do
      @recorded_dnis.s1 = "123456789012345678901234567890123456789012345678901234567890"
      @recorded_dnis.should be_valid
    end
  
    it "should not allow s1 (call type) to have a 61 characters" do
      @recorded_dnis.s1 = "1234567890123456789012345678901234567890123456789012345678901"
      @recorded_dnis.should_not be_valid
    end
  
    it "should not allow an asterisk in a string longer than 1" do
      @recorded_dnis.s1 = "1234567890123456*78789012345678901"
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow | characters in s1 (call type)' do
      @recorded_dnis.s1 = "TESt||inging"
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow empty string in s1 (call type)' do
      @recorded_dnis.s1 = ""
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow spaces in s1 (call type)' do
      @recorded_dnis.s1 = "   "
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow nil s1 (call type)' do
      @recorded_dnis.s1 = nil
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow spaces s1 (call type)' do
      @recorded_dnis.s1 = "    "
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow commas in s1 (call type)' do
      @recorded_dnis.s1 = "akje,asfasdf"
      @recorded_dnis.should_not be_valid
    end
  
    it 'should enforce the composite primary key upon creation for app id' do
      @recorded_dnis.app_id = nil
      @recorded_dnis.should_not be_valid
      @recorded_dnis.save.should eql(false)
    end
  
    it 'should enforce the composite primary key upon creation for parm_name' do
      @recorded_dnis.parm_name = nil
      @recorded_dnis.should_not be_valid
      @recorded_dnis.save.should eql(false)
    end
  
    it 'should enforce the composite primary key upon creation for parm_key' do
      @recorded_dnis.parm_key = nil
      @recorded_dnis.should_not be_valid
      @recorded_dnis.save.should eql(false)
    end
  
    it 'should always be of type R when created or saved' do
      @recorded_dnis.type.should eql('R')
  
    end
  
    it "should set the type to 'R' before validating" do
      @recorded_dnis.type = 'asfadsf'
      @recorded_dnis.should be_valid
    end
  
    it 'only allows for mass assignment of: s1, s2, i1, i2, i3' do
      recorded_dnis = RecordedDnis.new(:parm_name => 'test_parm_name', :parm_key => 'test_parm_key', :app_id => 1111, :s1 => 's1', :s2 => '1234567890', :i1 => 1, :i2 => 2, :i3 => 3, :i2_unused => true, :i3_unused => true)
  
      recorded_dnis.parm_name.should eql(nil)
      recorded_dnis.parm_key.should eql(nil)
      recorded_dnis.app_id.should eql(nil)
  
      recorded_dnis.s1.should eql('s1')
      recorded_dnis.s2.should eql('1234567890')
      recorded_dnis.i1.should eql(1)
      recorded_dnis.i2.should eql(2)
      recorded_dnis.i3.should eql(3)
    end
  
    it 'should default all iN values to integers before validation' do
  
      @recorded_dnis.should be_valid
  
      @recorded_dnis.i1.should eql(0)
      @recorded_dnis.i2.should eql(-1)
      @recorded_dnis.i3.should eql(-1)
    end
  
    it 'should default i2 (smallest number of transfers) to -1 if i2 is empty' do
      @recorded_dnis.i2 = ""
      @recorded_dnis.save
      @recorded_dnis.i2.should be(-1)
    end
  
    it 'should default i2 (smallest number of transfers) to -1 if i2 is empty' do
      @recorded_dnis.i2 = nil
      @recorded_dnis.save
      @recorded_dnis.i2.should be(-1)
    end
  
    it 'should allow i2 to be 0' do
      @recorded_dnis.i2 = 0
      @recorded_dnis.should be_valid
    end
  
    it 'should allow i2 to be 999' do
      @recorded_dnis.i2 = 999
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow i2 to be 1000' do
      @recorded_dnis.i2 = 1000
      @recorded_dnis.should_not be_valid
    end
  
  
    it 'should default i3 (survey score) to -1 if i2 is empty' do
      @recorded_dnis.i3 = ""
      @recorded_dnis.save
      @recorded_dnis.i3.should be(-1)
    end
  
    it 'should default i3 (survey score) to -1 if i2 is empty' do
      @recorded_dnis.i3 = nil
      @recorded_dnis.save
      @recorded_dnis.i3.should be(-1)
    end
  
    it 'should allow 0 as a value for (i1) recording percentage' do
      @recorded_dnis.i1 = 0
      @recorded_dnis.should be_valid
    end
  
    it 'should allow 100 as a value for (i1) recording percentage' do
      @recorded_dnis.i1 = 100
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow -1 as a value for (i1) recording percentage' do
      @recorded_dnis.i1 = -1
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow 101 as a value for (i1) recording percentage' do
      @recorded_dnis.i1 = 101
      @recorded_dnis.should_not be_valid
    end
  
    it 'requires Lowest survey score to trigger recording (i3) to be an integer greater than 0 or -1' do
      @recorded_dnis.should be_valid
  
      @recorded_dnis.i3 = -2
  
      @recorded_dnis.should_not be_valid
  
      @recorded_dnis.i3 = -1
  
      @recorded_dnis.should be_valid
  
      @recorded_dnis.i3 = 0
  
      @recorded_dnis.should_not be_valid
  
      @recorded_dnis.i3 = 1
  
      @recorded_dnis.should be_valid
  
      @recorded_dnis.i3 = '.6'
  
      @recorded_dnis.should_not be_valid
      @recorded_dnis.i3.should eql(0)
    end
  
    it 'should update the wildcard_dnis setting for this company in the racc_nvp table to be T if any recorded_dnis has a wildcard (*) for the DNIS (parm_key)' do
  
      # Create a new Recorded DNIS with a wildcard parm_key
      recorded_dnis = RecordedDnis.new
      recorded_dnis.app_id = @recorded_dnis.company.app_id
      recorded_dnis.parm_name = @recorded_dnis.parm_name
      recorded_dnis.parm_key = "*"
      recorded_dnis.s1 = @recorded_dnis.s1
      recorded_dnis.s2 = @recorded_dnis.s2
      recorded_dnis.i5 = 1
      recorded_dnis.should be_valid
      recorded_dnis.save.should eql(true)
  
      @company.company_config.wildcard_dnis.should == 'T'
    end
  
    it 'should update the wildcard_dnis setting for this company in the racc_nvp table to be F if there are now recorded_dnis values with a wildcard (*) for the DNIS (parm_key). (this will happen after save and after destroy)' do
      
      company_config = @company.company_config
  
      # Create a new Recorded DNIS with a wildcard parm_key
      recorded_dnis_with_wildcard = RecordedDnis.new
      recorded_dnis_with_wildcard.app_id = @recorded_dnis.company.app_id
      recorded_dnis_with_wildcard.parm_name = @recorded_dnis.parm_name
      recorded_dnis_with_wildcard.parm_key = "*"
      recorded_dnis_with_wildcard.s1 = @recorded_dnis.s1
      recorded_dnis_with_wildcard.s2 = @recorded_dnis.s2
      recorded_dnis_with_wildcard.i5 = 1
  
      recorded_dnis_with_wildcard.should be_valid
      recorded_dnis_with_wildcard.save.should eql(true)
  
      company_config.reload
      company_config.wildcard_dnis.should == 'T'
  
      # Create a new Recorded DNIS without parm_key
      recorded_dnis_no_wild = RecordedDnis.new
      recorded_dnis_no_wild.app_id = @recorded_dnis.company.app_id
      recorded_dnis_no_wild.parm_name = @recorded_dnis.parm_name
      recorded_dnis_no_wild.parm_key = "12344"
      recorded_dnis_no_wild.s1 = @recorded_dnis.s1
      recorded_dnis_no_wild.s2 = @recorded_dnis.s2
      recorded_dnis_no_wild.i5 = 1
  
      recorded_dnis_no_wild.should be_valid
      recorded_dnis_no_wild.save.should eql(true)
  
      recorded_dnis_no_wild.company.company_config.wildcard_dnis.should == 'T'
  
      # Delete the Wildcard Recorded DNIS
      recorded_dnis_with_wildcard.destroy
      
      company_config.reload
      company_config.wildcard_dnis.should == 'F'
    end
  
  
    ############# Tests for i5 & s2  (Destination and destionation type)
    ############ i5 = 1
    it 'should allow s2 (destination) with i5 (destination type) = 1 exactly equal to 10 digits' do
      @recorded_dnis.i5 = 1
      @recorded_dnis.s2 = '1234567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 1 should allow *' do
      @recorded_dnis.i5 = 1
      @recorded_dnis.s2 = '*'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 1 exactly equal to 11 digits' do
      @recorded_dnis.i5 = 1
      @recorded_dnis.s2 = '12345678901'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 1 exactly equal to 9 digits' do
      @recorded_dnis.i5 = 1
      @recorded_dnis.s2 = '123456789'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 1 to be blank' do
      @recorded_dnis.i5 = 1
      @recorded_dnis.s2 = ''
      @recorded_dnis.should_not be_valid
    end
  
    ########## i5 = 2
    it 'should allow s2 (destination) with i5 (destination type) = 2 to have 2 - 9 digits' do
      @recorded_dnis.i5 = 2
      @recorded_dnis.s2 = '12'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 2 to have 2 - 9 digits' do
      @recorded_dnis.i5 = 2
      @recorded_dnis.s2 = '123456789'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 2 should allow *' do
      @recorded_dnis.i5 = 2
      @recorded_dnis.s2 = '*'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 2 to be blank' do
      @recorded_dnis.i5 = 2
      @recorded_dnis.s2 = ''
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 2 to have 1 digit' do
      @recorded_dnis.i5 = 2
      @recorded_dnis.s2 = '3'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 2 to have 10 digit' do
      @recorded_dnis.i5 = 2
      @recorded_dnis.s2 = '1234567890'
      @recorded_dnis.should_not be_valid
    end
  
    ########## i5 = 3
    it 'should allow s2 (destination) with i5 (destination type) = 3 to have exactly 10 digits + 2 -9 digits' do
      @recorded_dnis.i5 = 3
      @recorded_dnis.s2 = '1234567890+12'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 3 to have to have a *' do
      @recorded_dnis.i5 = 3
      @recorded_dnis.s2 = '*'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 3 to have to exactly 10 digits' do
      @recorded_dnis.i5 = 3
      @recorded_dnis.s2 = '1234567890'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 3 to have to exactly 14 digits with no plus' do
      @recorded_dnis.i5 = 3
      @recorded_dnis.s2 = '12345678901234'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 3 to have less than 10 digits' do
      @recorded_dnis.i5 = 3
      @recorded_dnis.s2 = '123456'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 3 to be empty' do
      @recorded_dnis.i5 = 3
      @recorded_dnis.s2 = ''
      @recorded_dnis.should_not be_valid
    end
  
    ######### i5 = 4
    it 'should allow s2 (destination) with i5 (destination type) = 4 exactly equal to 10 digits' do
      @recorded_dnis.i5 = 4
      @recorded_dnis.s2 = '1234567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 4 should allow *' do
      @recorded_dnis.i5 = 4
      @recorded_dnis.s2 = "*"
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 4 exactly equal to 11 digits' do
      @recorded_dnis.i5 = 4
      @recorded_dnis.s2 = '12345678901'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 4 exactly equal to 9 digits' do
      @recorded_dnis.i5 = 4
      @recorded_dnis.s2 = '123456789'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 4 to be blank' do
      @recorded_dnis.i5 = 4
      @recorded_dnis.s2 = ''
      @recorded_dnis.should_not be_valid
    end
  
    ######### i5 = 5
    it 'should allow s2 (destination) with i5 (destination type) = 5 should resemble sip:user@vailsys.com' do
      @recorded_dnis.i5 = 5
      @recorded_dnis.s2 = 'sip:user@vailsys.com'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 5 should allow *' do
      @recorded_dnis.i5 = 5
      @recorded_dnis.s2 = '*'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 5 with digits only' do
      @recorded_dnis.i5 = 5
      @recorded_dnis.s2 = '12345678901'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 5 without the colon separating the sip prefix' do
      @recorded_dnis.i5 = 5
      @recorded_dnis.s2 = 'sipuser@vailsys.com'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 5 without the @ separator' do
      @recorded_dnis.i5 = 5
      @recorded_dnis.s2 = 'sip:uservailsys.com'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 5 without the . separator' do
      @recorded_dnis.i5 = 5
      @recorded_dnis.s2 = 'sip:user@vailsyscom'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 5 to be blank' do
      @recorded_dnis.i5 = 5
      @recorded_dnis.s2 = ''
      @recorded_dnis.should_not be_valid
    end
  
    ######### i5 = 6
    it 'should allow s2 (destination) with i5 (destination type) = 6 to have one digit' do
      @recorded_dnis.i5 = 6
      @recorded_dnis.s2 = '1'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 6 to have one letter' do
      @recorded_dnis.i5 = 6
      @recorded_dnis.s2 = '1'
      @recorded_dnis.should be_valid
    end
  
    # It seems there may be more rules surround the period
    it 'should allow s2 (destination) with i5 (destination type) = 6 to have one period' do
      @recorded_dnis.i5 = 6
      @recorded_dnis.s2 = '.'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 6 to have 20 digits' do
      @recorded_dnis.i5 = 6
      @recorded_dnis.s2 = '12345678901234567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 6 to have 20 letters' do
      @recorded_dnis.i5 = 6
      @recorded_dnis.s2 = 'qwertyuioplkjhgfdsaz'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 6 should allow *' do
      @recorded_dnis.i5 = 6
      @recorded_dnis.s2 = '*'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 6 with a length of 21 digit/chars' do
      @recorded_dnis.i5 = 6
      @recorded_dnis.s2 = '123456789012345678901'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 6 to be blank' do
      @recorded_dnis.i5 = 6
      @recorded_dnis.s2 = ''
      @recorded_dnis.should_not be_valid
    end
  
    ######### i5 = 7
    it 'should allow s2 (destination) with i5 (destination type) = 7 to have one digit' do
      @recorded_dnis.i5 = 7
      @recorded_dnis.s2 = '1'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 7 to have one letter' do
      @recorded_dnis.i5 = 7
      @recorded_dnis.s2 = '1'
      @recorded_dnis.should be_valid
    end
  
    # It seems there may be more rules surround the period
    it 'should allow s2 (destination) with i5 (destination type) = 7 to have one period' do
      @recorded_dnis.i5 = 7
      @recorded_dnis.s2 = '.'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 7 to have 30 digits' do
      @recorded_dnis.i5 = 7
      @recorded_dnis.s2 = '123456789012345678901234567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 7 to have 30 letters' do
      @recorded_dnis.i5 = 7
      @recorded_dnis.s2 = 'qwerty.ioplkjhgfdsazsdfghjkmnb'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 7 should allow *' do
      @recorded_dnis.i5 = 7
      @recorded_dnis.s2 = '*'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 7 with a length of 31 digit/chars' do
      @recorded_dnis.i5 = 7
      @recorded_dnis.s2 = '1234567890123456789012345678901'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 7 to be blank' do
      @recorded_dnis.i5 = 7
      @recorded_dnis.s2 = ''
      @recorded_dnis.should_not be_valid
    end
  
    ######### i5 = 8
    it 'should allow s2 (destination) with i5 (destination type) = 8 to have one digit' do
      @recorded_dnis.i5 = 8
      @recorded_dnis.s2 = '1'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 8 to have one letter' do
      @recorded_dnis.i5 = 8
      @recorded_dnis.s2 = '1'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 8 to have one period' do
      @recorded_dnis.i5 = 8
      @recorded_dnis.s2 = '.'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 8 to have 30 digits' do
      @recorded_dnis.i5 = 8
      @recorded_dnis.s2 = '123456789012345678901234567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 8 to have 30 digits with plus symbols included' do
      @recorded_dnis.i5 = 8
      @recorded_dnis.s2 = '12345678901234567+901+34567890'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 8 to have 30 letters' do
      @recorded_dnis.i5 = 8
      @recorded_dnis.s2 = 'qwerty.ioplkjhgfdsazsdfghjkmnb'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should allow s2 (destination) with i5 (destination type) = 8 should allow *' do
      @recorded_dnis.i5 = 8
      @recorded_dnis.s2 = '*'
      @recorded_dnis.should be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 8 with a length of 31 digit/chars' do
      @recorded_dnis.i5 = 8
      @recorded_dnis.s2 = '1234567890123456789012345678901'
      @recorded_dnis.should_not be_valid
    end
  
    it 'should not allow s2 (destination) with i5 (destination type) = 8 to be blank' do
      @recorded_dnis.i5 = 8
      @recorded_dnis.s2 = ''
      @recorded_dnis.should_not be_valid
    end
  
    it "should set i4 to 1 when i5 is 1" do
      @recorded_dnis.i5 = 1
      @recorded_dnis.save
      @recorded_dnis.i4.should equal(1)
    end
  
    it "should set i4 to 2 when i5 is 2" do
      @recorded_dnis.i5 = 2
      @recorded_dnis.save!
      @recorded_dnis.i4.should equal(2)
    end
  
    it "should set i4 to 3 when i5 is 3" do
      @recorded_dnis.i5 = 3
      @recorded_dnis.save
      @recorded_dnis.i4.should equal(3)
    end
  
    it "should set i4 to 3 when i5 is 4" do
      @recorded_dnis.i5 = 4
      @recorded_dnis.save
      @recorded_dnis.i4.should equal(3)
    end
  
    it "should set i4 to 3 when i5 is 5" do
      @recorded_dnis.i5 = 5
      @recorded_dnis.save
      @recorded_dnis.i4.should equal(3)
    end
  
    it "should set i4 to 3 when i5 is 6" do
      @recorded_dnis.i5 = 6
      @recorded_dnis.save
      @recorded_dnis.i4.should equal(4)
    end
  
    it "should set i4 to 3 when i5 is 7" do
      @recorded_dnis.i5 = 7
      @recorded_dnis.save
      @recorded_dnis.i4.should equal(5)
    end
  
    it "should set i4 to 3 when i5 is 8" do
      @recorded_dnis.i5 = 8
      @recorded_dnis.save
      @recorded_dnis.i4.should equal(3)
    end
    
    it "should be valid -1 value for i6 (Recording Retention Days)" do
      @recorded_dnis.i6 = -1
      @recorded_dnis.should be_valid
    end

    it "should not be valid when i6 (Retention Days) is 0" do
      @recorded_dnis.i6 = 0
      @recorded_dnis.should_not be_valid
    end

    it "should not be valid when i6 (Retention Days) is -2" do
      @recorded_dnis.i6 = -2
      @recorded_dnis.should_not be_valid
    end

    it "should not be valid when i6 (Retention Days) is 366" do
      @recorded_dnis.i6 = -366
      @recorded_dnis.should_not be_valid
    end

    it "should be valid when i6 (Retention Days) is 1" do
      @recorded_dnis.i6 = 1
      @recorded_dnis.should be_valid
    end

    it "should be valid when i6 (Retention Days) is 365" do
      @recorded_dnis.i6 = 365
      @recorded_dnis.should be_valid
    end
    
  end
  
  describe "update_wildcard_dnis_setting" do
    
    before(:each) do
      company = FactoryGirl.create(:company, :app_id => 25)
      @company_config = company.company_config
      @wildcard_setting = FactoryGirl.create(:setting, :app_id => company.app_id, :name => 'wildcard_dnis', :value => 'F')
      @recorded_dnis = FactoryGirl.create(:recorded_dnis, :app_id => company.app_id, :parm_key => '7878')
      @recorded_dnis_list = [ FactoryGirl.create(:recorded_dnis, :app_id => company.app_id, :parm_key => '1234567890'),
                              FactoryGirl.create(:recorded_dnis, :app_id => company.app_id, :parm_key => '*') ]
    end
    
    it "should set the wildcard dnis setting to 'T' if there are wildcard recorded dnis settings" do
      RecordedDnis.should_receive(:wildcards?).with(any_args).and_return true
      @recorded_dnis.update_wildcard_dnis_setting  
      
      @company_config.reload
      @company_config.wildcard_dnis.should == 'T'
      
    end
    
    it "should set the wildcard dnis setting to 'F' if there are NOT any wildcard recorded dnis settings" do
      RecordedDnis.should_receive(:wildcards?).with(any_args).and_return false
      @recorded_dnis.update_wildcard_dnis_setting  
    
      @setting = Setting.find_by_name('wildcard_dnis', :conditions => {:app_id => 25})
      @company_config.reload
      
      @setting.value.should == 'F'
      @company_config.wildcard_dnis.should == 'F'
    end
    
  end
  
  describe "wildcards?" do
    
    before(:each) do
      @company = FactoryGirl.create(:company)      
    end
    
    it "should return true if a wildcard rule exists in the company" do
      FactoryGirl.create(:recorded_dnis, :parm_key => '*', :app_id => @company.app_id)
      RecordedDnis.wildcards?(@company.app_id).should == true
    end
    
    it "should return false if a wildcard rule does not exist in the company" do
      FactoryGirl.create(:recorded_dnis, :parm_key => '1234567890', :app_id => @company.app_id)
      RecordedDnis.wildcards?(@company.app_id).should == false
    end
    
    it "should return false if a wildcard rule exists, but not in the company" do
      another_company = FactoryGirl.create(:company, :app_id => 123)
      FactoryGirl.create(:recorded_dnis, :parm_key => '*', :app_id => another_company.app_id)
      RecordedDnis.wildcards?(@company.app_id).should == false
    end
    
    it "should return false if there are no rules for the company" do
      RecordedDnis.where(:app_id => @company.app_id).size.should == 0
      RecordedDnis.wildcards?(@company.app_id).should == false
    end
    
    
  end
  
  describe "update_vlabels" do
    before(:each) do
      @app_id = 2
    end
    
    context "creating a rule" do
      
      context "while recording by rules is on" do
        before(:each) do
          @company = FactoryGirl.create(:company, :app_id => @app_id, :recording_type => 'R')
          @vlm1 = FactoryGirl.create(:vlabel_map, :app_id => @app_id, :vlabel => "12345", :full_call_recording_enabled => 'F', :full_call_recording_percentage => 0)
          @vlm2 = FactoryGirl.create(:vlabel_map, :app_id => @app_id, :vlabel => "67890", :full_call_recording_enabled => 'F', :full_call_recording_percentage => 0)
        end

        it "should update the recording settings all vlabels in the company when a wildcard rule is created" do
          recorded_dnis = FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => "*")

          @vlm1.reload
          @vlm2.reload

          @vlm1.full_call_recording_enabled.should == "M"
          @vlm1.full_call_recording_percentage.should == 100
          @vlm2.full_call_recording_enabled.should == "M"
          @vlm2.full_call_recording_percentage.should == 100
        end

        it "should update the recording settings only on the created vlabel" do
          recorded_dnis = FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => @vlm1.vlabel)

          @vlm1.reload
          @vlm2.reload

          @vlm1.full_call_recording_enabled.should == "M"
          @vlm1.full_call_recording_percentage.should == 100
          @vlm2.full_call_recording_enabled.should == "F"
          @vlm2.full_call_recording_percentage.should == 0
        end
      end
      
      context "while recording by rules is off" do
        it "should not update any vlabels if the company recording by rules setting is off" do
          @company = FactoryGirl.create(:company, :app_id => @app_id, :recording_type => 'P', :full_call_recording_percentage => 50)
          @vlm1 = FactoryGirl.create(:vlabel_map, :app_id => @app_id, :vlabel => "12345", :full_call_recording_enabled => 'T', :full_call_recording_percentage => 50)
          
          recorded_dnis = FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => @vlm1.vlabel)

          @vlm1.reload

          @vlm1.full_call_recording_enabled.should == "T"
          @vlm1.full_call_recording_percentage.should == 50
        end
      end
      
    end
    
    context "deleting a rule" do
      
      context "while recording by rules is on" do
        before(:each) do
          @company = FactoryGirl.create(:company, :app_id => @app_id, :recording_type => 'R')
          @vlm1 = FactoryGirl.create(:vlabel_map, :app_id => @app_id, :vlabel => "12345", :full_call_recording_enabled => 'M', :full_call_recording_percentage => 100)
          @vlm2 = FactoryGirl.create(:vlabel_map, :app_id => @app_id, :vlabel => "67890", :full_call_recording_enabled => 'M', :full_call_recording_percentage => 100)
        end

        context "delete a wildcard rule" do
          before(:each) do
            @recorded_dnis = FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => "*", :parm_name => "wildcard_to_delete")
          end

          context "when another wildcard rule exists" do
            it "should keep rule recording settings on all vlabels" do
              FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => "*", :parm_name => "wildcard_to_keep")
              @recorded_dnis.destroy

              @vlm1.reload
              @vlm2.reload

              @vlm1.full_call_recording_enabled.should == "M"
              @vlm1.full_call_recording_percentage.should == 100
              @vlm2.full_call_recording_enabled.should == "M"
              @vlm2.full_call_recording_percentage.should == 100
            end
          end

          context "when there are no more wildcard rules" do
            it "should remove rule recording settings on vlabels that don't have rules and keep them on vlabels that have rules" do
              FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => @vlm1.vlabel)
              @recorded_dnis.destroy

              @vlm1.reload
              @vlm2.reload

              @vlm1.full_call_recording_enabled.should == "M"
              @vlm1.full_call_recording_percentage.should == 100
              @vlm2.full_call_recording_enabled.should == "F"
              @vlm2.full_call_recording_percentage.should == 0
            end
          end
        end        
      
        context "delete a non-wildcard rule" do
          before(:each) do
            @recorded_dnis = FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => @vlm1.vlabel, :parm_name => "rule_to_delete")
          end
        
          context "when another wildcard rule exists" do
            it "should keep rule recording settings on that vlabel" do
              FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => "*", :parm_name => "wildcard_to_keep")
              @recorded_dnis.destroy
            
              @vlm1.reload
            
              @vlm1.full_call_recording_enabled.should == "M"
              @vlm1.full_call_recording_percentage.should == 100
            end
          end
        
          context "when there are no more wildcard rules" do
            it "should remove rule recording settings on the deleted vlabel" do
              @recorded_dnis.destroy
            
              @vlm1.reload
            
              @vlm1.full_call_recording_enabled.should == "F"
              @vlm1.full_call_recording_percentage.should == 0
            end
          end
        end
      end
      
      context "while recording by rules is off" do
        it "should not update any vlabels if the company recording by rules setting is off" do
          @company = FactoryGirl.create(:company, :app_id => @app_id, :recording_type => 'D')
          recorded_dnis = FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => '12345', :parm_name => "rule_to_delete")
          @vlm1 = FactoryGirl.create(:vlabel_map, :app_id => @app_id, :vlabel => "12345")

          recorded_dnis.destroy

          @vlm1.reload

          @vlm1.full_call_recording_enabled.should == "T"
          @vlm1.full_call_recording_percentage.should == 100
        end
      end
      
    end
    
  end
  
  describe "has_rule_for_vlabel?" do
    before(:each) do
      @app_id = 123
      FactoryGirl.create(:company, :app_id => @app_id)
    end
    
    it "should return true if a wildcard exists" do
      FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => '*')
      RecordedDnis.has_rule_for_vlabel?(@app_id, '1234567').should == true
    end
    
    it "should return true if a rule for the vlabel exists" do
      FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => '1234567')
      RecordedDnis.has_rule_for_vlabel?(@app_id, '1234567').should == true
    end
    
    it "should return false if there are no rules" do
      RecordedDnis.has_rule_for_vlabel?(@app_id, '1234567').should == false
    end
    
    it "should return false if there is no rule for the vlabel and no wildcard" do
      FactoryGirl.create(:recorded_dnis, :app_id => @app_id, :parm_key => '555')
      RecordedDnis.has_rule_for_vlabel?(@app_id, '1234567').should == false
    end
  end

end
