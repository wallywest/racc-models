# require File.dirname(__FILE__) + '/../spec_helper'
# require File.dirname(__FILE__) + '/../helpers/factory.rb'
# 
# describe BulkLoad do
#     
#   it "should validate b numbers " do
#      BulkLoad.valid( "./bulk_load/b_number.data" , "./bulk_load/phone_numbers_schema.yaml" ) 
#    end
#    
#    it "should validate f numbers " do 
#      BulkLoad.valid( "./bulk_load/f_numbers.data" , "./bulk_load/phone_numbers_schema.yaml" )
#    end
#    
#    it "should invalidate a b_number file with schema validation errors" do
#      BulkLoad.valid( "./bulk_load/b_number_invalid.data" , "./bulk_load/phone_numbers_schema.yaml" ).should be(false)
#    end
#    
#    it "should invalidate a f_number file with schema validation errors" do
#      BulkLoad.valid( "./bulk_load/f_numbers_invalid.data" , "./bulk_load/phone_numbers_schema.yaml" ).should be(false)
#    end
#    
#    it "should load a single yaml file and build web objects " do
#      phone_ids = BulkLoad.yaml_load(File.open( "./bulk_load/b_number.data"))   
#      phone = PhoneNumber.find(phone_ids[0])
#      
#      phone.packages.length.should == 2
#      phone.packages[0].profiles.length.should == 2
#      phone.packages[0].profiles[0].time_segments.length.should == 3
#      phone.packages[0].profiles[0].time_segments[0].routings.length == 2
#      phone.packages[0].profiles[0].time_segments[0].routings[0].routing_exits.length.should == 4
#    end
#    
#    it "should load f numbers " do 
#      phone_ids = BulkLoad.yaml_load(File.open( "./bulk_load/f_numbers.data" ))   
#      phone_ids.length.should == 14
#    end
#    
#    it "should load f and numbers " do
#      files = ["./bulk_load/b_number.data", "./bulk_load/f_numbers.data"] 
#      phone_ids = BulkLoad.load(files)   
#      phone_ids.length.should == 15
#    end
#    
#    it "should check day as true with t" do
#      BulkLoad.check_day("t").should be(true)
#    end
#    
#    it "should check day as false with f" do
#      BulkLoad.check_day("f").should be(false)
#    end
#    
#    it "should unzip a zip file to the bulk update temp area" do
#      BulkLoad.unzip_to_temp("./bulk_load/archive.zip")
#      Dir.entries("./bulk_load/temp/").length.should == 7
#      BulkLoad.remove_temp_files  
#    end
#    
#    it "should remvoe all files from the temp bulk upload directory " do
#      BulkLoad.remove_temp_files 
#      Dir.entries("./bulk_load/temp/").length.should == 2 # Should have . and .. in the directory
#    end
#    
#    it "should return true if an extension is zip " do
#      BulkLoad.zip?("jake.zip").should be(true)
#    end
#    
#    it "should return false if the extension is not a zip" do
#      BulkLoad.zip?("jake.yaml").should be(false)
#    end
#    
#    it "should process zip files end to end " do
#      BulkLoad.process("./bulk_load/archive.zip").length.should == 15
#    end
#   
#    it "should process zip files end to end " do
#      BulkLoad.process("./bulk_load/b_number.data").length.should == 1
#    end
#   
#    it "should convert a time to minutes " do
#      TimeSegment.time_to_minutes("3:43 PM").should == 943
#      TimeSegment.time_to_minutes("3:43 AM").should == 223
#      TimeSegment.time_to_minutes("11:43 AM").should == 703
#      TimeSegment.time_to_minutes("11:43 PM").should == 1423    
#      TimeSegment.time_to_minutes("12:00 AM").should == 0    
#    end
#   
# end
