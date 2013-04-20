require 'spec_helper'

describe Company do

  it "sets blanks to nil for UI customization fields" do
    @company = FactoryGirl.create(:company, :logo_file_name => "", :stylesheet => "")
    @company.logo_file_name.should == nil
    @company.stylesheet.should == nil
  end
  
  describe "validations" do
    before(:each) do
      @company = FactoryGirl.build(:company)
    end
    
    it "should be valid" do
      @company.should be_valid
    end
    
    it "should not be valid if the app id already exists" do
      app_id = 1234
      FactoryGirl.create(:company, :app_id => 1234)
      @company.app_id = 1234
      @company.should_not be_valid
    end
    
    it "should not be valid if the name is missing" do
      @company.name = ""
      @company.should_not be_valid
      @company.name = nil
      @company.should_not be_valid
    end
    
    it "should not be valid if max recording length is not a number" do
      @company.max_recording_length = 'test_value'
      @company.should_not be_valid
    end
    
    it "should allow valid recording types" do
      ['P','R','D'].each do |rec_type|
        @company.recording_type = rec_type
        @company.should be_valid
      end
    end
    
    it "should not allow invalid recording types" do
      ['p','A',0,123].each do |rec_type|
        @company.recording_type = rec_type
        @company.should_not be_valid
      end      
    end
    
    it "should not be valid if the full call recording percentage is not a number" do
      @company.recording_type = 'P'
      @company.full_call_recording_percentage = 'abc'
      @company.should_not be_valid
    end
    
    it "should allow valid split full recording values" do
      @company.full_call_recording_enabled = 'T'
      @company.full_call_recording_percentage = 50
      ['T','F'].each do |split_value|
        @company.split_full_recording = split_value
        @company.should be_valid
      end      
    end
    
    it "should not allow invalid split full recording values" do
      ['A','t',0,123].each do |split_value|
        @company.split_full_recording = split_value
        @company.should_not be_valid
      end            
    end

    it "should allow valid multi channel recording values" do
      @company.full_call_recording_enabled = 'T'
      @company.full_call_recording_percentage = 50
      @company.split_full_recording = 'T'
      ['T','F'].each do |multi_value|
        @company.multi_channel_recording = multi_value
        @company.should be_valid
      end
    end

    it "should not allow invalid multi channel recording values" do
      ['A','t',0,123].each do |multi_value|
        @company.multi_channel_recording = multi_value
        @company.should_not be_valid
      end            
    end
    
    it "should not be valid if multi channel is enabled and split is not enabled" do
      @company.split_full_recording = 'F'
      @company.multi_channel_recording = 'T'
      @company.should_not be_valid
    end
    
    it "should not be valid if split full recording is enabled and full call recording is not enabled" do
      @company.full_call_recording_enabled = 'F'
      @company.split_full_recording = 'T'
      @company.should_not be_valid
    end
    
    it "should not be valid if a non-integer of dynamic ivr actions is entered" do
      [-1, 1.5, 'hello'].each do |nbr|
        @company.max_dynamic_ivr_actions = nbr
        @company.should_not be_valid
      end
    end

    it "should not be valid if cache_refresh_limit is not an integer" do
      ["A","?","121A"].each do
        @company.cache_refresh_limit = "A"
        @company.should_not be_valid
      end
    end
    
    describe 'queuing_deactivation' do
      it 'should pass through if queuing is not being deactivated' do
        @company.queuing = 'active'
        @company.send(:queuing_deactivation)
        @company.errors.should be_empty
      end

      it "should pass through if none of the company's queue destinations are actively routed" do
        destination = mock_model(Destination, :has_routing? => false)
        Destination.should_receive(:only_queues).with(@company.app_id).and_return [destination]
        @company.send(:queuing_deactivation)
        @company.errors.should be_empty
      end
  
      it "should add an error if one of the company's queue destinations is actively routed" do
        destination = mock_model(Destination, :has_routing? => true)
        Destination.should_receive(:only_queues).with(@company.app_id).and_return [destination]
        @company.send(:queuing_deactivation)
        @company.errors.size.should == 1
        @company.errors.full_messages.first.should =~ /Queuing cannot be inactivated/
      end
    end

    describe :max_destinations do
      before do
        @dest = FactoryGirl.create(:destination)
        @company = FactoryGirl.create(:company, :app_id => 101)
        @ts = FactoryGirl.create(:time_segment, :app_id => @company.app_id)
        @routing = FactoryGirl.create(:routing, :time_segment => @ts)
        @re = FactoryGirl.create(:destination_exit, :routing => @routing, :exit => @dest, :call_priority => 1)
      end

      it 'passes through if the max destinations setting is greater than existing counts' do
        @company.max_destinations_for_time_segment = 2
        @company.send(:check_max_exits)
        @company.errors.count.should == 0
      end

      it 'pass through if the max destinations setting is equal to existing counts' do
        @company.max_destinations_for_time_segment = 1
        @company.send(:check_max_exits)
        @company.errors.count.should == 0
      end

      it 'adds an error if the max destinations setting is less than existing counts' do
        @company.max_destinations_for_time_segment = 0
        @company.send(:check_max_exits)
        @company.errors.count.should == 1
      end
    end
  end
  
  describe "updating" do
    before do
      @company = FactoryGirl.build(:company, :app_id => 0001)
    end
  
    it 'should have access to a max recording length attribute' do
      @company.max_recording_length = 1000
      @company.max_recording_length.should eql(1000)
    end
  
    it 'should update its max recording length' do
      @company.app_id = 0001
      @company.subdomain = 'asdf'
      @company.name = 'asdf'
  
      @company.should be_valid
      @company.save.should eql(true)
  
      @company = Company.find_by_app_id_and_subdomain(0001, 'asdf')
      @company.max_recording_length = 1000
  
      @company.save.should eql(true)
  
      @company = Company.find_by_app_id_and_subdomain(0001, 'asdf')
      @company.max_recording_length.should eql(1000)
    end
  
    it 'should have many settings' do
      @company.app_id = 0001
      @company.subdomain = 'asdf'
      @company.name = 'asdf'
      @company.save
  
      setting1 = Setting.new
      setting1.app_id = @company.app_id
      setting1.name = 'test_setting_1'
      setting1.value = 'test value'
  
      setting1.should be_valid
      setting1.save.should eql(true)
      @company.settings << setting1
  
      setting2 = Setting.new
      setting2.app_id = @company.app_id
      setting2.name = 'test_setting_2'
      setting2.value = 'test value'
  
      setting2.should be_valid
      setting2.save.should eql(true)
      @company.settings << setting2
  
      @company = Company.find_by_app_id_and_subdomain(0001, 'asdf')
  
      @company.settings.include?(setting1).should eql(true)
      @company.settings.include?(setting2).should eql(true)
    end
  
  end
  
  describe "post_call_enabled?" do
    
    before(:each) do
      @app_id = 1
      @company = FactoryGirl.create(:company, :app_id => @app_id)
    end
    
    it "should return true if the post_call setting is enabled for any operation in that company" do
      operation = FactoryGirl.create(:operation, :app_id => @app_id, :post_call => 'T')
      @company.post_call_enabled?.should == true
    end
    
    it "should return false if the post_call setting is not enabled for any operation in that company" do
      operation = FactoryGirl.create(:operation, :app_id => @app_id, :post_call => 'F')
      @company.post_call_enabled?.should == false
    end
    
  end
  
  describe "set_recording_settings" do
    
    it "should set full_call_recording_enabled to T and defer_discard to F when recording by percentage" do
      initialize_company
      @company.recording_type = 'P'
      @company.full_call_recording_percentage = 2
      @company.send(:set_recording_settings)
      @company.full_call_recording_enabled.should == 'T'
      @company.company_config.defer_discard.should == 'F'
    end
    
    it "should set full_call_recording_enabled to M and defer_discard to F when recording by real time rules" do
      initialize_company
      @company.recording_type = 'R'
      @company.send(:set_recording_settings)
      @company.full_call_recording_enabled.should == 'M'
      @company.full_call_recording_percentage.should == 100
      @company.company_config.defer_discard.should == 'F'      
    end
    
    it "should set full_call_recording_enabled to M, full_call_recording_percentage to 100, and defer_discard to F when recording by deferred rules" do
      initialize_company
      @company.recording_type = 'D'
      @company.send(:set_recording_settings)
      @company.full_call_recording_enabled.should == 'T'
      @company.full_call_recording_percentage.should == 100
      @company.company_config.defer_discard.should == 'T'      
    end
    
    it "should set full_call_recording_enabled to F if the full call recording percentage is 0" do
      initialize_company('T', 10)
      @company.recording_type = 'P'
      @company.full_call_recording_percentage = 0
      @company.send(:set_recording_settings)
      @company.full_call_recording_enabled.should == 'F'
    end
    
    def initialize_company(enabled='F', percent=0)
      @company = FactoryGirl.build(:company, :full_call_recording_enabled => enabled, :full_call_recording_percentage => percent)
    end
  end

  describe "update_recording_settings_for_vlabels" do
    context "updating settings" do
      before(:each) do
        @call_percent = 60
        @company = FactoryGirl.create(:company)
        @company.company_config.update_attributes(:recording_enabled => 'T')
        @vlm = FactoryGirl.create(:vlabel_map, :app_id => @company.app_id)
      end

      it "should set the correct recording settings for all of the vlabels in the company" do
        @company.update_attributes({
          :full_call_recording_enabled => 'F', 
          :full_call_recording_percentage => @call_percent, 
          :recording_type => 'P', 
          :split_full_recording => 'T',
          :multi_channel_recording => 'T'})

        @vlm.reload
        @vlm.full_call_recording_enabled.should == 'T'
        @vlm.full_call_recording_percentage.should == @call_percent
        @vlm.split_full_recording.should == 'T'
        @vlm.multi_channel_recording.should == 'T'
      end

      it "should not update the recording settings for vlabels if the company recording settings have not changed" do
        @company.update_attributes(:street => '123 Main St', :process_family => 'test_family', :stylesheet => 'test_css')

        @vlm.reload
        @vlm.full_call_recording_enabled.should == 'F'
        @vlm.full_call_recording_percentage.should == 0
        @vlm.split_full_recording.should == 'F'
        @vlm.multi_channel_recording.should == 'F'      
      end
    end

    context "logic for updating" do
      before(:each) do
        @company = FactoryGirl.create(:company)
        @company.should_receive(:recording_settings_changed?).and_return true
      end
      
      it "should call update_vlabels_based_on_rec_rules if the 'Rules: Real Time' option is chosen and there is no wildcard rule" do
        @company.should_receive(:recording_type).and_return "R"
        RecordedDnis.should_receive(:wildcards?).with(@company.app_id).and_return false
        @company.should_receive(:update_vlabels_based_on_rec_rules)
        
        @company.send(:update_recording_settings_for_vlabels)
      end
      
      it "should NOT call update_vlabels_based_on_rec_rules if the 'Rules: Real Time' option is not chosen" do
        @company.should_receive(:recording_type).and_return "P"
        RecordedDnis.should_not_receive(:wildcards?).with(@company.app_id)
        @company.should_not_receive(:update_vlabels_based_on_rec_rules)
        
        @company.send(:update_recording_settings_for_vlabels)
      end

      it "should NOT call update_vlabels_based_on_rec_rules if there is a wildcard rule" do
        @company.should_receive(:recording_type).and_return "R"
        RecordedDnis.should_receive(:wildcards?).with(@company.app_id).and_return true
        @company.should_not_receive(:update_vlabels_based_on_rec_rules)
        
        @company.send(:update_recording_settings_for_vlabels)
      end
    end
    
  end

  describe "update_modified_time_unix" do
    it "should update the modified_time_unix field in racc companies after save" do
      @company = FactoryGirl.build(:company, :app_id => 0001)
      @company.company_config.modified_time_unix = nil
      @company.save
      @company.company_config.modified_time_unix.should_not == nil
    end
  end

  describe "recording_settings_changed?" do
    
    context "company config fields" do
      it "should return true if the recording_enabled field has changed" do
        company = FactoryGirl.create(:company)
        company.company_config.update_attributes(:recording_enabled => 'F')

        company.company_config.recording_enabled = 'T'
        company.send(:recording_settings_changed?).should == true
      end      
    end
    
    context "company fields" do
      before(:each) do
        @company = FactoryGirl.create(:company, 
          :recording_type => 'P', 
          :full_call_recording_enabled => 'F',
          :full_call_recording_percentage => 0,
          :split_full_recording => 'F',
          :multi_channel_recording => 'F')
      end
      
      it "should return true if the recording_type field has changed" do
        @company.recording_type = 'M'
        @company.send(:recording_settings_changed?).should == true
      end      

      it "should return true if the split_full_recording field has changed" do
        @company.split_full_recording = 'T'
        @company.send(:recording_settings_changed?).should == true
      end     
      
      it "should return true if the multi_channel_recording field has changed" do
        @company.multi_channel_recording = 'T'
        @company.send(:recording_settings_changed?).should == true
      end 
    end

  end

  describe "can_refresh_cache?" do
    context "there has never been a cache refresh" do
      it "should return true if there has never been a cache" do
        company = FactoryGirl.create(:company)
        company.can_refresh_cache?.should == true
      end
    end

    context "there has been a cache refresh" do
      before(:each) do
        @company = FactoryGirl.create(:company)
        @company.last_cache_refresh_on = Time.now
        @company.cache_refresh_limit = 300
      end

      it "should return false if the time is within the cache_refresh_limit" do
        @now = Time.now
        threemin = @now + 180
        Time.stub!(:now).and_return(threemin)

        @company.can_refresh_cache?.should == false
      end

      it "should return true if cache_refresh_limit has been exceeded" do
        @now = Time.now
        fivemin = @now + 300
        Time.stub!(:now).and_return(fivemin)

        @company.can_refresh_cache?.should == true
      end
    end
  end
  
  describe "update_vlabels_based_on_rec_rules" do
    before(:each) do
      @company = FactoryGirl.create(:company, :recording_type => 'R', :full_call_recording_enabled => 'M', :full_call_recording_percentage => 100)
    end
    
    it "should set full_call_recording_enabled = 'M' and full_call_recording_percentage = 100 for vlabels that have rules" do
      vlm = FactoryGirl.create(:vlabel_map, :app_id => @company.app_id, :vlabel => 12345, :full_call_recording_enabled => 'F', :full_call_recording_percentage => 0)
      FactoryGirl.create(:recorded_dnis, :parm_key => vlm.vlabel)

      @company.send(:update_vlabels_based_on_rec_rules)
      vlm.reload
      
      vlm.full_call_recording_enabled.should == 'M'
      vlm.full_call_recording_percentage.should == 100
    end
    
    it "should set full_call_recording_enabled = 'F' and full_call_recording_percentage = 0 for vlabels that don't have rules" do
      vlm = FactoryGirl.create(:vlabel_map, :app_id => @company.app_id, :vlabel => 11111, :full_call_recording_enabled => 'M', :full_call_recording_percentage => 100)
      FactoryGirl.create(:recorded_dnis, :parm_key => "45555")

      @company.send(:update_vlabels_based_on_rec_rules)
      vlm.reload
      
      vlm.full_call_recording_enabled.should == 'F'
      vlm.full_call_recording_percentage.should == 0
    end
    
    it "should set full_call_recording_enabled = 'F' and full_call_recording_percentage = 0 for vlabels when there are no rules" do
      vlm = FactoryGirl.create(:vlabel_map, :app_id => @company.app_id, :vlabel => 11111, :full_call_recording_enabled => 'F', :full_call_recording_percentage => 0)

      @company.send(:update_vlabels_based_on_rec_rules)
      vlm.reload
      
      vlm.full_call_recording_enabled.should == 'F'
      vlm.full_call_recording_percentage.should == 0
    end
    
  end

  describe "default_admin_report" do
    let(:company){ FactoryGirl.build(:company) }
    let(:admin_report){ FactoryGirl.build(:admin_report) }

    subject{ company.default_admin_report }

    it "should return the default report for the company" do
      ar_relation = mock(ActiveRecord::Relation)
      AdminReport.should_receive(:where).with("app_id = ? AND name = ?", company.app_id, AdminReport::DEFAULT_NAME).and_return ar_relation
      ar_relation.should_receive(:first).and_return admin_report

      should == admin_report
    end
    
    it "should create a default report if one doesn't exist" do
      AdminReport.should_receive(:where).with("app_id = ? AND name = ?", company.app_id, AdminReport::DEFAULT_NAME).and_return nil
      AdminReport.should_receive(:create).with(any_args).and_return admin_report

      should == admin_report
    end
  end

  describe :allows_route_to_vlabels? do
    let(:company) { Company.new(route_to_options: option) }
    subject { company.allows_route_to_vlabels? }

    context "when route_to_options is set to Destinations Only" do
      let(:option) { ROUTE_TO_DEST }
      it { should be_false }
    end

    context "when route_to_options is set to Destinations and Vlabels" do
      let(:option) { ROUTE_TO_VLM }
      it { should be_true }
    end

    context "when route_to_options is set to Destinations and Prompts" do
      let(:option) { ROUTE_TO_MEDIA }
      it { should be_false }
    end

    context "when route_to_options is set to All" do
      let(:option) { ROUTE_TO_ALL }
      it { should be_true }
    end
  end

  describe :allows_route_to_media? do
    let(:company) { Company.new(route_to_options: option) }
    subject { company.allows_route_to_media? }

    context "when route_to_options is set to Destinations Only" do
      let(:option) { ROUTE_TO_DEST }
      it { should be_false }
    end

    context "when route_to_options is set to Destinations and Vlabels" do
      let(:option) { ROUTE_TO_VLM }
      it { should be_false }
    end

    context "when route_to_options is set to Destinations and Prompts" do
      let(:option) { ROUTE_TO_MEDIA }
      it { should be_true }
    end

    context "when route_to_options is set to All" do
      let(:option) { ROUTE_TO_ALL }
      it { should be_true }
    end
  end

  describe :availability_of_route_to do
    let(:company) { Company.new(route_to_options: option) }

    context "when route_to_options is set to Destinations Only" do
      let(:option) { ROUTE_TO_DEST }

      it "adds an error if vlabels are in use" do
        company.send(:availability_of_route_to)
        company.errors.should have(1).item
      end

      it "adds an error if prompts are in use" do
        company.send(:availability_of_route_to)
        company.errors.should have(1).item
      end

      it "passes through if only destinations are in use" do
        company.send(:availability_of_route_to)
        company.errors.should be_empty
      end
    end

    context "when route_to_options is set to Destinations and Vlabels" do
      let(:option) { ROUTE_TO_VLM }
      it { should be_false }
    end

    context "when route_to_options is set to Destinations and Prompts" do
      let(:option) { ROUTE_TO_MEDIA }
      it { should be_true }
    end

    context "when route_to_options is set to All" do
      let(:option) { ROUTE_TO_ALL }
      it { should be_true }
    end
  end
end
