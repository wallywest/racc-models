require File.dirname(__FILE__) + '/../spec_helper'

describe DestinationProperty do
  before(:each) do
    @destination_property = FactoryGirl.build :destination_property
  end
  
  it "should be valid" do
    @destination_property.should be_valid
  end
  
  it "should be invalid if a validation_format is not selected" do
    @destination_property.validation_format = nil
    @destination_property.should be_invalid

    @destination_property.validation_format = ''
    @destination_property.should be_invalid
  end
  
  it "should have a valid dial or block value" do 
    @destination_property.dial_or_block = 'D'
    @destination_property.should be_valid
    
    @destination_property.dial_or_block = 'B'
    @destination_property.should be_valid
    
    
    @destination_property.dial_or_block = 'd'
    @destination_property.should_not be_valid
    
    @destination_property.dial_or_block = 'b'
    @destination_property.should_not be_valid
    
    @destination_property.dial_or_block = '1.1'
    @destination_property.should_not be_valid
    
    @destination_property.dial_or_block = ''
    @destination_property.should_not be_valid
  end
  
  it "should have a valid pass parent call ID" do
    @destination_property.pass_parentcallID = 'T'
    @destination_property.should be_valid
    
    @destination_property.pass_parentcallID = 'F'
    @destination_property.should be_valid
    
    @destination_property.pass_parentcallID = 't'
    @destination_property.should_not be_valid
    
    @destination_property.pass_parentcallID = 'f'
    @destination_property.should_not be_valid
    
    @destination_property.pass_parentcallID = 'q'
    @destination_property.should_not be_valid
    
    @destination_property.pass_parentcallID = ''
    @destination_property.should_not be_valid
  end
  
  it "should have a valid CDR auth value" do
    @destination_property.cdr_auth = 'T'
    @destination_property.should be_valid
    
    @destination_property.cdr_auth = 'F'
    @destination_property.should be_valid
    
    @destination_property.cdr_auth = 't'
    @destination_property.should_not be_valid
    
    @destination_property.cdr_auth = 'f'
    @destination_property.should_not be_valid
    
    @destination_property.cdr_auth = 'y'
    @destination_property.should_not be_valid
    
    @destination_property.cdr_auth = '1'
    @destination_property.should_not be_valid
    
    @destination_property.cdr_auth = ''
    @destination_property.should_not be_valid
  end
  
  describe "allowed outdial format values" do
    
    it "should be between 0 and 11" do
      @destination_property.outdial_format = -1
      @destination_property.should_not be_valid
      
      @destination_property.outdial_format = 0
      @destination_property.should be_valid
      
      @destination_property.outdial_format = 11
      @destination_property.should be_valid
      
      @destination_property.outdial_format = 12
      @destination_property.should_not be_valid
    end
    
  end
  
  describe "default values" do
    
    it "defaults proper values for commands_ok, dtmf_from_o, dtmf_to_o, dest_loc, and isup_enabled" do
      @destination_property.commands_ok.should == 'T'
      @destination_property.dtmf_from_o.should == 'F'
      @destination_property.dtmf_to_o.should == 'F'
      @destination_property.dest_loc.should == 'V'
      @destination_property.isup_enabled.should == 0
      @destination_property.cti_routine == 0
      @destination_property.queue_cti == ''
    end
    
  end
  
  describe "allowed destination property name values" do
    it "allows letters, numbers, *, _, -, and #" do
      destination = FactoryGirl.build(:destination_property, :destination_property_name => "ABCDEFGabcdefgwxyzWXYZ1234567890_-#*")
      destination.should be_valid
    end
    
    it "disallows all other characters" do
      destination = FactoryGirl.build(:destination_property, :destination_property_name => "destination?")
      destination.should_not be_valid
      
      destination = FactoryGirl.build(:destination_property, :destination_property_name => "destination,")
      destination.should_not be_valid
      
      destination = FactoryGirl.build(:destination_property, :destination_property_name => "destination)")
      destination.should_not be_valid
      
      destination = FactoryGirl.build(:destination_property, :destination_property_name => "destination(?)")
      destination.should_not be_valid
      
      destination = FactoryGirl.build(:destination_property, :destination_property_name => "destination%")
      destination.should_not be_valid
      
      #etc...
    end
    
  end
  
  describe "allowed transfer method values" do
    it "does not allow nulls" do
      @destination_property.transfer_method = ''
      @destination_property.should_not be_valid
    end
    
    it "validates that the transfer method is in the set of allowed values" do
      DestinationProperty.transfer_method_values.each do |val|
        @destination_property.transfer_method = val
        @destination_property.should be_valid
      end
    end
    
    it "rejects all other values" do
      ["Bat", "7", "131", "Zf", "L"].each do |val|
        @destination_property.transfer_method = val
        @destination_property.should_not be_valid
      end
    end
    
    it "should allow zero" do
      @destination_property.transfer_method = "0"
      @destination_property.should be_valid      
    end
  end
  
  describe "allowed transfer type values" do
    it "does not allow nulls" do
      @destination_property.transfer_type = ''
      @destination_property.should_not be_valid
    end
    
    it "validates that the transfer type is in the set of allowed values" do
      DestinationProperty.transfer_type_values.each do |val|
        @destination_property.transfer_type = val
        @destination_property.should be_valid
      end
    end
    
    it "rejects all other values" do
      ["Bat", "7", "131", "Zf", "L"].each do |val|
        @destination_property.transfer_type = val
        @destination_property.should_not be_valid
      end
    end
    
  end
  
  describe "allowed tranfer lookup format values" do
    it "validates that the transfer lookup value is in a specific set" do
      DestinationProperty.transfer_lookup_values.each do |val|
        @destination_property.transfer_lookup = val
        @destination_property.should be_valid
      end
    end
    
    it "rejects all other values" do
      ["Bat", "7", 'Z', '131'].each do |val|
        @destination_property.transfer_lookup = val
        @destination_property.should_not be_valid
      end
    end
    
  end
  
  describe "allowed transfer pattern values" do
    it "validates that the transfer pattern value is in a specific set" do
      DestinationProperty.transfer_pattern_values.each do |val|
        @destination_property.transfer_pattern = val
        @destination_property.should be_valid
      end
    end
    
    it "rejects all other values" do
      ["Bat", "7", 'K' '131'].each do |val|
        @destination_property.transfer_pattern = val
        @destination_property.should_not be_valid
      end
    end
    
    it "does not allows blanks" do
      @destination_property.transfer_pattern = ''
      @destination_property.should_not be_valid
    end
    
  end
  
  describe "allowed agent type values" do
    it "validates that the agent type is in the set of allowed values" do
      DestinationProperty.agent_type_values.each do |val|
        @destination_property.agent_type = val
        @destination_property.should be_valid
      end
    end
    
    it "rejects all other values" do
      ['', 'Z', 7, 'sheep', '4', false].each do |val|
        @destination_property.agent_type = val
        @destination_property.should_not be_valid
      end
    end
    
    it "does not allow nulls" do
      @destination_property.agent_type = nil
      @destination_property.should_not be_valid
    end
  end
  
  describe "allowed dest_loc values" do
    it "validates that the dest_loc is in the set of allowed values" do
      DestinationProperty.dest_loc_values.each do |val|
        @destination_property.dest_loc = val
        @destination_property.should be_valid
      end
    end
    
    it "rejects all other values" do
      ['', 'Z', 7, 'sheep', '4', false, nil].each do |val|
        @destination_property.dest_loc = val
        @destination_property.should_not be_valid
      end
    end
  end
  
  describe "allowed commands_ok values" do
    it "validates that the dest_loc is in the set of allowed values" do
      ['T', 'F'].each do |val|
        @destination_property.commands_ok = val
        @destination_property.should be_valid
      end
    end
    
    it "rejects all other values" do
      ['', 'Z', 7, 'sheep', '4', false, nil, 't', 'f'].each do |val|
        @destination_property.commands_ok = val
        @destination_property.should_not be_valid
      end
    end
  end
  
  describe "allowed dtmf_from_o values" do
    it "validates that the dest_loc is in the set of allowed values" do
      ['T', 'F'].each do |val|
        @destination_property.dtmf_from_o = val
        @destination_property.should be_valid
      end
    end
    
    it "rejects all other values" do
      ['', 'Z', 7, 'sheep', '4', false, nil, 't', 'f'].each do |val|
        @destination_property.dtmf_from_o = val
        @destination_property.should_not be_valid
      end
    end
  end
  
  describe "allowed dtmf_to_o values" do
    it "validates that the dest_loc is in the set of allowed values" do
      ['T', 'F'].each do |val|
        @destination_property.dtmf_to_o = val
        @destination_property.should be_valid
      end
    end
    
    it "rejects all other values" do
      ['', 'Z', 7, 'sheep', '4', false, nil, 't', 'f'].each do |val|
        @destination_property.dtmf_to_o = val
        @destination_property.should_not be_valid
      end
    end
  end
  
  describe "allowed isup_enabled values" do
    it "validates isup_enabled is a non-negative int that fits in 11 bytes or less" do
      [0, 1, 5, 11, 200, 2 ** (8 * 11) - 1].each do |val|
        @destination_property.isup_enabled = val
        @destination_property.should be_valid
      end
    end
    
    it "rejects all other values" do
      [ -1, '', 'Z', 'sheep', nil, 't', 'f', 0.5, 2 ** (8 * 11)].each do |val|
        @destination_property.isup_enabled = val
        @destination_property.should_not be_valid
      end
    end
  end
  
  describe "allowed target_ack values" do
    it "accepts numbers, # and *" do
      @destination_property.target_ack = "345"
      @destination_property.should be_valid
      
      @destination_property.target_ack = "*345"
      @destination_property.should be_valid
      
      @destination_property.target_ack = "34#5"
      @destination_property.should be_valid
    end
    
    it "accepts A-D" do
      @destination_property.target_ack = "ABCD"
      @destination_property.should be_valid
    end
    
    it "accepts blanks" do
      @destination_property.target_ack = nil
      @destination_property.should be_valid
    end
    
    it "does not accept any other strings" do
      @destination_property.target_ack = "not a number"
      @destination_property.should_not be_valid
    end
  end
  
  describe "pre-save hooks" do
    it "computes the value of isup_enabled if one of the fields is set" do
      @destination_property.isup_enabled = 0
      @destination_property.copy_isup_data = 0x01
      @destination_property.valid?
      @destination_property.isup_enabled.should == 1
      
      @destination_property.isup_enabled = 0
      @destination_property.copy_isup_oli = 0x02
      @destination_property.valid?
      @destination_property.isup_enabled.should == 3
      
    end
    
    it "leaves isup_enabled alone if neither field is set" do
      @destination_property.isup_enabled = 13
      @destination_property.valid?
      @destination_property.isup_enabled.should == 13
    end
  end
  
  describe "destination_attribute_bits" do
    it "should be invalid if the value is not between 0 and 2147483647" do
      ['a', -1, 3000000000, 2147483648, '', nil].each do |nbr|
        @destination_property.destination_attribute_bits = nbr
        @destination_property.should be_invalid
      end
    end
    
    it "should be invalid if the value is not an integer" do
      [3999.2, -8.5].each do |nbr|
        @destination_property.destination_attribute_bits = nbr
        @destination_property.should be_invalid
      end
    end
  end

  describe :allows_mapping? do
    subject { destination_property.allows_mapping? }

    context "when dtype is 'M'" do
      let(:destination_property) { DestinationProperty.new(:dtype => 'M') }
      it { should be_true }
    end

    context "when dtype is not 'M'" do
      let(:destination_property) { DestinationProperty.new(:dtype => 'D') }
      it { should be_false }
    end
  end
  
  describe "ani_override" do
    it "should be valid if the value has 1 to 14 digits" do
      [2, 3242432434, 12345678901234].each do |ao|
        @destination_property.ani_override = ao
        @destination_property.should be_valid
      end
    end
    
    it "should be invalid if the value is not a positive integer" do
      ['hello', -1, 2.5].each do |ao|
        @destination_property.ani_override = ao
        @destination_property.should be_invalid
      end
    end
    
    it "should be invalid if the value is longer than 14 digits" do
      @destination_property.ani_override = 123456789012345
      @destination_property.should be_invalid
    end
    
    it "should be valid if the value is blank" do
      @destination_property.ani_override = ""
      @destination_property.should be_valid
    end
  end


  describe 'hidden destionation properties' do
    describe 'scopes' do
      before :each do
        @destination_property.hidden = true
        @destination_property.save
      end
      it 'should not appear in the default scope' do
        expect(DestinationProperty.all).not_to include(@destination_property)
      end
      it 'should appear in anonymous scopes' do
        expect(DestinationProperty.unscoped).to include(@destination_property)
      end
    end
    describe 'hiding an assigned destination property' do
      subject(:destination_property) { FactoryGirl.create :destination_property }
      before :each do
        @destination = FactoryGirl.create :destination, destination_property_name: destination_property.destination_property_name
        destination_property.hidden = true
      end
      it { should_not be_valid }
    end
  end

  
end
