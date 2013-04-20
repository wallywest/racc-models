require 'spec_helper'

describe Location do

  describe "for_mapped_dest_autocomplete" do
    before(:each) do
      @app_id = 1
      @phrase = "test"
      @default_dest = FactoryGirl.create(:destination)
    end
    
    it "should find valid destinations" do
      dest = FactoryGirl.create(:destination, :destination => @phrase)
      Location.for_mapped_dest_autocomplete(@app_id, @phrase).should == [dest]
    end
    
    it "should not find any locations" do
      dp = FactoryGirl.create(:destination_property, :dtype => "M", :app_id => @app_id, :destination_property_name => "mapped_name")
      FactoryGirl.create(:location, :destination => @phrase, :app_id => @app_id, :destination_property_name => dp.destination_property_name)
      
      Location.for_mapped_dest_autocomplete(@app_id, @phrase).should == []
    end
    
    it "should not find any queue destinations" do
      dp = FactoryGirl.create(:destination_property, :agent_type => "Q", :app_id => @app_id, :destination_property_name => "queue_name")
      FactoryGirl.create(:location, :destination => @phrase, :app_id => @app_id, :destination_property_name => dp.destination_property_name)
      
      Location.for_mapped_dest_autocomplete(@app_id, @phrase).should == []
    end
    
    it "should return [] if destinations do not exist" do
      Location.for_mapped_dest_autocomplete(@app_id, @phrase).should == []
    end
    
    it "should not return queue destinations if there are no locations" do
      dest = FactoryGirl.create(:destination, :destination => "#{@phrase}_1")
      q_dp = FactoryGirl.create(:destination_property, :agent_type => "Q", :app_id => @app_id, :destination_property_name => "queue_prop_name")
      FactoryGirl.create(:location, :destination => @phrase, :app_id => @app_id, :destination_property_name => q_dp.destination_property_name)

      Location.for_mapped_dest_autocomplete(@app_id, @phrase).should == [dest]
    end

    it "should not return locations if there are no queue destinations" do
      dest = FactoryGirl.create(:destination, :destination => "#{@phrase}_1")
      loc_dp = FactoryGirl.create(:destination_property, :dtype => "M", :app_id => @app_id, :destination_property_name => "loc_prop_name")
      FactoryGirl.create(:location, :destination => @phrase, :app_id => @app_id, :destination_property_name => loc_dp.destination_property_name)

      Location.for_mapped_dest_autocomplete(@app_id, @phrase).should == [dest]
    end
    
  end

  describe "with_default_exits" do
    before do
      @loc = FactoryGirl.create(:destination)
      @loc.destination_property.update_attributes(:dtype => "M")
    end

    it "should only return default exits" do
      default_exit = FactoryGirl.create(:destination)
      dest_exit = FactoryGirl.create(:destination)
      create_default(default_exit)
      FactoryGirl.create(:label_destination_map, :vlabel_map_id => 123, :mapped_destination_id => @loc.id, :exit_id => dest_exit.id, :exit_type => "Destination")

      locs = Location.with_default_exits(@loc.app_id)
      locs.size.should == 1
      locs.first.exit_type.should == "Destination"
      locs.first.exit_label.should == default_exit.destination
    end

    it "should return the destination as the exit_label for destinations" do
      dest = FactoryGirl.create(:destination)
      create_default(dest)

      loc = Location.with_default_exits(@loc.app_id).first
      loc.exit_type.should == "Destination"
      loc.exit_label.should == dest.destination
    end

    it "should return the vlabel as the exit_label for vlabel maps" do
      vlm = FactoryGirl.create(:vlabel_map)
      create_default(vlm)

      loc = Location.with_default_exits(@loc.app_id).first
      loc.exit_type.should == "VlabelMap"
      loc.exit_label.should == vlm.vlabel
    end

    it "should return the keyword as the exit_label for media files" do
      pending "re-arch recording test db"
      test_db = Rails.configuration.database_configuration['test']['database']
      Rails.stub_chain(:configuration, :database_configuration).and_return ({'test' => {'adapter' => 'mysql2'}, 'vail_recording' => {'database' => test_db}})

      mf = FactoryGirl.create(:media_file)
      create_default(mf)
      loc = Location.with_default_exits(@loc.app_id).first
      loc.exit_type.should == "MediaFile"
      loc.exit_label.should == mf.keyword
    end

    def create_default(exit)
      FactoryGirl.create(:label_destination_map, :vlabel_map_id => nil, :mapped_destination_id => @loc.id, :exit_id => exit.id, :exit_type => exit.class.to_s)
    end
  end

end
