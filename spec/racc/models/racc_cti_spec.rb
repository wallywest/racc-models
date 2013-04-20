require 'spec_helper'

describe RaccCti do

    before(:each) do
      @cti = FactoryGirl.build(:racc_cti)
    end
    
    it "should be valid" do
      @cti.should be_valid
    end
    
    context "cti_name" do
      it "should be invalid if it is already in use" do
        existing_cti = FactoryGirl.create(:racc_cti)
        @cti.cti_name = existing_cti.cti_name
        @cti.should be_invalid
      end

      it "should be valid if it is already in use but in a different app_id" do
        existing_cti = FactoryGirl.create(:racc_cti, :app_id => @cti.app_id + 1)
        @cti.cti_name = existing_cti.cti_name
        @cti.should be_valid
      end

      it "should be invalid if it is blank" do
        [nil, ""].each do |name|
          @cti.cti_name = name
          @cti.should be_invalid
        end
      end
      
      it "should be invalid if it is longer than 64 characters" do
        long_name = ""
        65.times.each {|nbr| long_name += nbr.to_s}
        @cti.cti_name = long_name
        @cti.should be_invalid
      end
      
      it "should be valid if it is shorter than 65 characters" do
        ["hello", "aldkfasfjaslfjsalkfjslafjlsfjsl"].each do |name|
          @cti.cti_name = name
          @cti.should be_valid
        end
      end
    end
    
    context "cti_order" do
      it "should be valid if it is zero" do
        @cti.cti_order = 0
        @cti.should be_valid
      end
      
      it "should be invalid if it is blank" do
        [nil, ""].each do |order|
          @cti.cti_order = order
          @cti.should be_invalid
        end
      end

      it "should be invalid if it is not an integer" do
        ["a", 1.2].each do |order|
          @cti.cti_order = order
          @cti.should be_invalid
        end
      end
      
      it "should be invalid if it is less than zero" do
        @cti.cti_order = -1
        @cti.should be_invalid
      end
    end
    
    context "vendor_type" do
      it "should be valid if it is one character" do
        @cti.vendor_type = 'C'
        @cti.should be_valid
      end
      
      it "should be invalid if it is longer than one character" do
        @cti.vendor_type = "no"
        @cti.should be_invalid
      end
      
      it "should be invalid if it is blank" do
        [nil, ""].each do |vt|
          @cti.vendor_type = vt
          @cti.should be_invalid
        end
      end
    end

end
