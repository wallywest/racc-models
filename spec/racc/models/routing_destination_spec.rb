require 'spec_helper'

describe RoutingDestination, exclude: true do
  before do
    @dest = mock_model(Destination)
    @rd = FactoryGirl.build(:routing_destination, :destination => @dest)
  end

  describe :copy do
    before do
      @rd.created_at = Time.now
      @rd.updated_at = Time.now
    end
    
    subject { @rd.copy }
    
    it { should be_new_record }
    its(:destination_id) { should eq(@rd.destination_id) }
    its(:created_at) { should be_nil }
    its(:updated_at) { should be_nil }
  end

  describe :assign_destination do
    context 'with a blank destination_string' do
      it 'does not try to find a destination' do
        Destination.should_not_receive(:find_by_destination_and_app_id)
        @rd.send(:assign_destination)
      end
    end

    context 'with a non-blank destination_string' do
      let(:dest) { mock_model(Destination) }

      before do
        @rd.destination_string = '000'
        Destination.stub(:find_by_destination_and_app_id) { dest }
      end

      it 'finds the destination' do
        Destination.should_receive(:find_by_destination_and_app_id).with(@rd.destination_string, @rd.app_id)
        @rd.send(:assign_destination)
      end

      it 'sets the destination' do
        @rd.send(:assign_destination)
        @rd.destination.should be(dest)
      end
    end
  end

  describe :existence_of_dequeue_label do
    context 'with an existing vlabel' do
      it 'does not generate an error' do
        VlabelMap.stub(:find_by_vlabel_and_app_id).with(@rd.dequeue_label, @rd.app_id) { stub }
        @rd.send(:existence_of_dequeue_label)
        @rd.errors.should be_empty
      end
    end

    context 'with a non-existing vlabel' do
      it 'generates an error' do
        VlabelMap.stub(:find_by_vlabel_and_app_id).with(@rd.dequeue_label, @rd.app_id)
        @rd.send(:existence_of_dequeue_label)
        @rd.errors.should have(1).item
      end
    end
  end

  describe :destination_is_queue? do
    context 'with a destination' do
      it 'returns false if the destination is not a queue' do
        @dest.stub(:is_queue?) { false }
        @rd.send(:destination_is_queue?).should be_false
      end

      it 'returns true if the destination is a queue' do
        @dest.stub(:is_queue?) { true }
        @rd.send(:destination_is_queue?).should be_true
      end
    end

    context 'without a destination' do
      it 'returns false' do
        @rd.destination = nil
        @rd.send(:destination_is_queue?).should be_false
      end
    end
  end

  describe :verification_of_destination do
    context 'with a valid destination' do
      it 'does not generate an error' do
        Destination.stub(:destination_verified_for_package) { true }
        @rd.send(:verification_of_destination)
        @rd.errors.should be_empty
      end
    end

    context 'with an invalid destination' do
      it 'generates an error' do
        Destination.stub(:destination_verified_for_package) { false }
        @rd.send(:verification_of_destination)
        @rd.errors.should have(1).item 
      end
    end

    context 'without a destination' do
      it 'does not generate an error' do
        @rd.destination = nil
        @rd.send(:verification_of_destination)
        @rd.errors.should be_empty
      end
    end
  end
end
