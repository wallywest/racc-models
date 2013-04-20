require 'spec_helper'

describe RoutingExit do
  describe :copy do
    before do
      @dest = mock_model(Destination)
      @rd = FactoryGirl.build(:routing_exit, :exit => @dest)

      @rd.created_at = Time.now
      @rd.updated_at = Time.now
    end
    
    subject { @rd.copy }
    
    it { should be_new_record }
    its(:exit_id) { should eq(@rd.exit_id) }
    its(:created_at) { should be_nil }
    its(:updated_at) { should be_nil }
  end

  describe "helper methods" do
    before do
      @dest = FactoryGirl.build(:destination)
      @vlabel = FactoryGirl.build(:vlabel_map)
      @rd = FactoryGirl.build(:routing_exit, :exit => @dest)
    end

    it "should have an exit object" do
      expect(@rd.exit_object).to be_kind_of(Exit)
    end

    it "should forward routing_exit methods to exit methods" do
      exit_obj = @rd.exit_object

      expect(@rd.exit_value).to eq(exit_obj.value)
      expect(@rd.exit_description).to eq(exit_obj.description)
      expect(@rd.exit_dequeue).to eq(exit_obj.dequeue_value)
    end

    it "destination_exit? should return true with destination exit" do
      expect(@rd.destination_exit?).to eq(true)
      expect(@rd.route_exit?).to eq(false)
    end

    it "route_exit? should return true with vlabel exit" do
      @rd.exit = @vlabel
      expect(@rd.route_exit?).to eq(true)
      expect(@rd.destination_exit?).to eq(false)
    end

    it "should have setter methods for nested_params input" do
      expect(@rd).to respond_to(:exit_has_dequeue=)
      expect(@rd).to respond_to(:exit_value=)
      expect(@rd).to respond_to(:exit_dequeue=)
    end
  end

  context "validations" do
    describe :presence_of_exit do
      it "should throw error when no exit is present" do
        @rd = FactoryGirl.build(:routing_exit, :exit_id => nil)

        @rd.save

        expect(@rd.errors[:exit_id]).to_not be_empty
      end
    end

    describe "verification of divr" do
      it "should throw error if divr is not allowed to be used" do
        @dest = mock_model(Destination)
        Destination.stub!(:destination_verified_for_package).and_return(false)
        @rd = FactoryGirl.build(:routing_exit, :exit => @dest)

        @rd.save

        expect(@rd.errors[:destination]).to_not be_empty
      end
    end

    describe "route_to_self" do
      it "should throw an error if exit is mapped to vlabel assigned to routing_exit" do
        nv = FactoryGirl.build(:vlabel_map)
        rd = FactoryGirl.build(:route_exit)
        rd.save

        rd.stub_chain(:routing,:time_segment,:profile,:package,:vlabel_map,:id).and_return(nv.id)
        rd.exit = nv
        rd.save

        expect(rd.errors[:package]).to_not be_empty
      end
    end

  end

  describe :routed_to, slow: true do
    it "scopes to the given type" do
      FactoryGirl.create(:routing_exit, exit_type: "Destination", exit_id: 1)
      FactoryGirl.create(:routing_exit, exit_type: "VlabelMap", exit_id: 1)
      RoutingExit.routed_to("Destination").should have(1).item
    end
  end
end
