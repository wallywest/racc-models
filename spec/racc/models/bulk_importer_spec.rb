require 'spec_helper'
require 'csv'

describe BulkImporter do
  
  before :each do
    @csv_file = mock "csv"
    ThreadLocalHelper.thread_local_app_id = 1
  end
  
  describe "initialize" do
    
    describe "when no file is provided" do
      
      it "should raise an exception" do
        lambda { BulkImporter.new }.should raise_error ArgumentError
      end
      
    end
    
    describe "when the file is a CSV" do
      
      it "should successfully invoke the constructor" do
        csv_string = "value1, value2, value3"
        @csv_file.stub!(:read).and_return(csv_string)
        
        BulkImporter.new @csv_file
      end
      
      it "should raise an exception when the CSV file is improperly formatted" do
        csv_string = "value1, value\"2, value3"
        @csv_file.stub!(:read).and_return(csv_string)
        
        lambda { BulkImporter.new @csv_file }.should raise_error DataFormatError
      end
      
    end
    
  end
  
  describe "process" do
    
    before :each do
      @destination_property = FactoryGirl.create(:destination_property)
    end
    
    describe "when the file is valid CSV data" do
      
      it "returns an array of the saved objects" do
        csv_string = 
<<-CSV_FILE 
type,destination,destination_title,destination_property_name,app_id
destination,5552340925,Test Destination,#{@destination_property.destination_property_name},1
CSV_FILE
        @csv_file.stub!(:read).and_return(csv_string)
        bi = BulkImporter.new @csv_file
        results = bi.process
        
        results.class.should == Array
        results.size.should == 1
        results.first.class.should == Destination
      end
      
    end
    
    describe "when the file is valid CSV but not valid RACC data" do
      
      it "adds to the errors list an invalid row error when the type of the row cannot be determined" do
        csv_string = 
<<-CSV_FILE 
type,destination,destination_title,destination_property_name,app_id
destinatoin,5552340925,Test Destination,#{@destination_property.destination_property_name},1
CSV_FILE
        @csv_file.stub!(:read).and_return(csv_string)
        bi = BulkImporter.new @csv_file
        results = bi.process
        
        bi.errors.size.should == 1
        bi.errors.first.line_number.should == 2
        bi.errors.first.message.should == "Cannot import data of the specified type because it is invalid : destinatoin"
      end
      
      it "adds to the errors list a type not permitted error when the type is not in the allowed list" do
        csv_string = 
<<-CSV_FILE 
type,destination,destination_title,destination_property_name,app_id
ani_group,5552340925,Test Destination,#{@destination_property.destination_property_name},1
CSV_FILE
        @csv_file.stub!(:read).and_return(csv_string)
        bi = BulkImporter.new @csv_file
        results = bi.process

        bi.errors.size.should == 1
        bi.errors.first.line_number.should == 2
        bi.errors.first.message.should == "Type not permitted for bulk import : ani_group"
        
      end
      
      it "adds to the errors list the ActiveRecord validation errors if the record failed validation" do
        csv_string = 
<<-CSV_FILE 
type,destination_title,destination_property_name,app_id
destination,Test Destination,#{@destination_property.destination_property_name},1
CSV_FILE
        @csv_file.stub!(:read).and_return(csv_string)
        bi = BulkImporter.new @csv_file
        results = bi.process

        bi.errors.size.should == 1
        bi.errors.first.message.should == "An error occurred while trying to save this record."
      end
      
      it "adds to the errors list an a generic error message if one or more rows raised a database exception" do
        csv_string = 
<<-CSV_FILE 
type,destination,destination_title,destination_property_name,app_id
destination,5552340925,Test Destination,#{@destination_property.destination_property_name},1
CSV_FILE
        
        destination = FactoryGirl.build(:destination)
        destination.should_receive(:save).and_raise ActiveRecord::StatementInvalid
        
        Destination.stub!(:new).with(any_args).and_return(destination)
        
        @csv_file.stub!(:read).and_return(csv_string)
        bi = BulkImporter.new @csv_file
        results = bi.process
        
        bi.errors.size.should == 1
        bi.errors.first.message.should == "An error occurred while trying to save this record."
      end
      
      it "continues processing subsequent rows to provide a complete accounting of validation errors in the file" do
        csv_string = 
<<-CSV_FILE 
type,destination,destination_title,destination_property_name,app_id
destinatoin,5552340925,Test Destination,#{@destination_property.destination_property_name},1
destination,5552340926,Test Destination 2,Invalid Property Name,1
CSV_FILE
        @csv_file.stub!(:read).and_return(csv_string)
        bi = BulkImporter.new @csv_file
        results = bi.process

        bi.errors.size.should == 2
      end
      
      it "does not save any values to the database" do
        csv_string = 
<<-CSV_FILE 
type,destination,destination_title,destination_property_name,app_id
destinatoin,5552340925,Test Destination,#{@destination_property.destination_property_name},1
destination,5552340926,Test Destination 2,#{@destination_property.destination_property_name},1
CSV_FILE
        @csv_file.stub!(:read).and_return(csv_string)
        bi = BulkImporter.new @csv_file
        results = bi.process
        
        Destination.all.size.should == 0
      end
      
    end
    
  end
  
end
