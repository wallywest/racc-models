require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'json'

describe DynamicIvr do
  
  describe "find_all_in_divrs" do
    context "prompts" do
      it "should return an array of prompt ids that are used in dynamic ivrs" do
        prompt_id = "123456"
        prompt_id_2 = "789012"
        DynamicIvr.create({
          :name => "test divr", 
          :app_id => 1,
          :json_string => "{
            \"data\":\"First DIVR\",
            \"metadata\":{\"default_error_msg_1\":\"\",\"remaining_actions\":25,\"total_actions\":30,\"tree_state\":\"Active\",\"invalid_msgs\":{},\"type\":\"root\",\"nbr_of_tries\":\"3\",\"default_goodbye_msg\":\"\",\"error_type\":\"default\"},
            \"children\":[{\"data\":\"Greeting\",\"metadata\":{\"prompt_id\":\"#{prompt_id}\",\"type\":\"announcement\"},\"attr\":{\"rel\":\"announcement\",\"id\":\"1311636448\"}}, {\"data\":\"Greeting2\",\"metadata\":{\"prompt_id\":\"#{prompt_id_2}\",\"type\":\"announcement\"},\"attr\":{\"rel\":\"announcement\",\"id\":\"1311636448\"}}],
            \"attr\":{\"rel\":\"root\",\"id\":\"1\"},\"state\":\"open\"
          }"
        })
        DynamicIvr.find_all_in_divrs(1,"prompts").should == [prompt_id, prompt_id_2]
      end
    
      it "should return default error messages" do
        default_msg_1 = "11111"
        default_msg_2 = "22222"
        error_out_msg = "33333"
        prompt_id = "123456"
        DynamicIvr.create({
          :name => "test divr", 
          :app_id => 1,
          :json_string => "{
            \"data\":\"First DIVR\",
            \"metadata\":{\"default_error_msg_1\":\"#{default_msg_1}\",\"default_error_msg_2\":\"#{default_msg_2}\",\"remaining_actions\":25,\"total_actions\":30,\"tree_state\":\"Active\",\"invalid_msgs\":{},\"type\":\"root\",\"nbr_of_tries\":\"3\",\"default_goodbye_msg\":\"#{error_out_msg}\",\"error_type\":\"default\"},
            \"children\":[{\"data\":\"Greeting\",\"metadata\":{\"prompt_id\":\"#{prompt_id}\",\"type\":\"announcement\"},\"attr\":{\"rel\":\"announcement\",\"id\":\"1311636448\"}}],
            \"attr\":{\"rel\":\"root\",\"id\":\"1\"},\"state\":\"open\"
          }"
        })
        DynamicIvr.find_all_in_divrs(1,"prompts").should == [default_msg_1, default_msg_2, error_out_msg, prompt_id]
      end

      it "should return and empty array if no prompts are found" do
        DynamicIvr.create({
          :name => "test divr", 
          :app_id => 1,
          :json_string => "{
            \"data\":{\"title\":\"divr three\"},
            \"metadata\":{\"type\":\"root\",\"nbr_of_tries\":\"3\",\"error_type\":\"default\",\"default_error_msg_1\":\"\",\"default_goodbye_msg\":\"\",\"remaining_actions\":30,\"total_actions\":30,\"tree_state\":\"In Progress\"},
            \"attr\":{\"id\":\"5\",\"rel\":\"root\"},
            \"children\":[{\"data\":\"<i>Assign action...</i>\",\"attr\":{\"id\":\"1311799695\",\"rel\":\"empty\"},\"metadata\":{\"type\":\"empty\"}}]
          }"
        })
        DynamicIvr.find_all_in_divrs(1,"prompts").should == []    
        DynamicIvr.find_all_in_divrs(1,"transfer_strings").should == []    
      end
    end
    
    context "transfer_strings" do
      it "should return an" do
        xfer_nbr = "test this 1st label: this[racc@vailsys.com/] transfer string"
        DynamicIvr.create({
          :name => "test divr", 
          :app_id => 1,
          :json_string => "{
            \"data\":{\"title\":\"divr three\"},
            \"metadata\":{\"type\":\"root\",\"nbr_of_tries\":\"3\",\"error_type\":\"default\",\"default_error_msg_1\":\"\",\"default_goodbye_msg\":\"\",\"remaining_actions\":30,\"total_actions\":30,\"tree_state\":\"In Progress\"},
            \"attr\":{\"id\":\"5\",\"rel\":\"root\"},
            \"children\":[{\"data\":\"Xfer\",\"metadata\":{\"number\":\"#{xfer_nbr}\",\"type\":\"transfer\"},\"attr\":{\"rel\":\"transfer\",\"id\":\"1311636448\"}}],
          }"
        })
        DynamicIvr.find_all_in_divrs(1,"transfer_strings").should == [xfer_nbr]
      end
    end
  end
    
  describe "copy_ivr" do
    before(:each) do
      @divr = DynamicIvr.create({
        :name => "test divr", 
        :app_id => 1,
        :json_string => "{
          \"data\":\"First DIVR\",
          \"metadata\":{\"default_error_msg_1\":\"\",\"remaining_actions\":25,\"total_actions\":30,\"tree_state\":\"Active\",\"invalid_msgs\":{},\"type\":\"root\",\"nbr_of_tries\":\"3\",\"default_goodbye_msg\":\"\",\"error_type\":\"default\"},
          \"children\":[],
          \"attr\":{\"rel\":\"root\",\"id\":\"1\"},\"state\":\"open\"
        }",
        :state => DynamicIvr::STATE_NEW
      })
    end
    
    it "should copy the divr successfully and return true" do
      copied_name = "Copied DIVR"
      
      @divr.copy_ivr(copied_name).should == true
      copied_divr = DynamicIvr.find_by_name(copied_name)
      copied_divr.name.should == copied_name
      copied_divr.state.should == DynamicIvr::STATE_NEW
      copied_json = JSON.parse(copied_divr.json_string)
      copied_json["data"].should == copied_name
      copied_json["metadata"]["tree_state"].should == DynamicIvr::STATE_NEW
      copied_json["attr"]["id"].should == copied_divr.id
    end
    
    it "should return false if the cloned ivr isn't valid and therefore didn't save" do
      copied_divr = FactoryGirl.build(:dynamic_ivr)
      @divr.should_receive(:dup).and_return copied_divr
      copied_divr.should_receive(:save).once.and_return false
      @divr.copy_ivr("new name").should_not == true
    end
    
    it "should return an error message if an error occurs while copying" do
      @divr.json_string = "{"
      @divr.save
      @divr.copy_ivr("new name").should rescue(Exception)

    end
    
    it "should save the copied state as valid if the original state is active or enabled" do
      [DynamicIvr::STATE_ACTIVE, DynamicIvr::STATE_ENABLED].each do |orig_state|
        @divr.state = orig_state
      
        copied_name = "Copied DIVR"
        @divr.copy_ivr(copied_name).should == true
        copied_divr = DynamicIvr.find_by_name(copied_name)
        copied_divr.state.should == DynamicIvr::STATE_VALID
      end
    end
    
    it "should save the copied state as invalid if the original state is invalid" do
      @divr.state = DynamicIvr::STATE_INVALID
    
      copied_name = "Copied DIVR"
      @divr.copy_ivr(copied_name).should == true
      copied_divr = DynamicIvr.find_by_name(copied_name)
      copied_divr.state.should == DynamicIvr::STATE_INVALID
    end
  end
  
  describe "save_state" do
    it "should save the tree state to the one that is passed in" do
      divr = FactoryGirl.create(:dynamic_ivr)

      divr.state.should == DynamicIvr::STATE_NEW
      old_ivr_string = JSON.parse(divr.json_string)
      old_ivr_string["metadata"]["tree_state"].should == DynamicIvr::STATE_NEW

      divr.save_state(DynamicIvr::STATE_ACTIVE)
      divr.state.should == DynamicIvr::STATE_ACTIVE
      new_ivr_string = JSON.parse(divr.json_string)
      new_ivr_string["metadata"]["tree_state"].should == DynamicIvr::STATE_ACTIVE
    end
  end  
end
