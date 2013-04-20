require 'spec_helper'

describe Exit do
  let(:type) { 'Destination' }
  let(:exit) {
    Exit.new({
      type: type, value: 'value', dequeue_value: 'd-value', after_prompt: ''
    }, 1234)
  }

  describe :initialize do
    subject { exit }

    context 'with form parameters' do
      it { should be_a(Exit) }
      its(:type) { should eq('Destination') }
      its(:value) { should eq('value') }
      its(:dequeue_value) { should eq('d-value') }
      its(:after_prompt) { should eq('') }
      its(:app_id) { should eq(1234) }
    end

    context 'with a racc_route_destination_xref' do
      let(:xref) {
        mock_model(RaccRouteDestinationXref,
          exit_type: 'VlabelMap',
          exit: mock_model(VlabelMap, vlabel: 'test label'),
          dequeue_label: 'd-value',
          app_id: 101)
      }
      let(:exit) { Exit.new(xref) }

      it { should be_a(Exit) }
      its(:type) { should eq('VlabelMap') }
      its(:value) { should eq('test label') }
      its(:dequeue_value) { should eq('d-value') }
      its(:after_prompt) { should eq('') }
      its(:app_id) { should eq(101) }
    end
  end

  describe :source do
    it 'finds the source object' do
      exit.should_receive(:find) { stub }
      exit.source
    end
    
    it 'memoizes the source object' do
      exit.should_receive(:find).once { stub }
      exit.source
      exit.source
    end
  end
  
  describe :description do
    context 'when source is not found' do
      it 'returns empty string' do
        exit.description.should eq('')
      end
    end

    context 'when source is a Destination' do
      it 'returns the destination title' do
        exit.stub(:source) { mock_model(Destination, destination_title: 'title') }
        exit.description.should eq('Destination: title')
      end
    end

    context 'when source is a VlabelMap' do
      it 'returns the vlabel description' do
        exit.stub(:source) { mock_model(VlabelMap, description: 'desc') }
        exit.description.should eq('Number/Label: desc')
      end
    end

    context 'when source is a MediaFile' do
      it 'returns the media file type label' do
        exit.stub(:source) { mock_model(MediaFile) }
        exit.description.should eq('Prompt')
      end
    end
  end

  describe :dtype do
    before do
      exit.stub(:source) { source }
    end

    subject { exit.dtype }

    context 'when source is not found' do
      let(:source) { nil }
      it { should eq('') }
    end
    
    context 'when source is a normal Destination' do
      let(:source) { mock_model(Destination, mappable?: false) }
      it { should eq('D') }
    end

    context 'when source is a mappable Destination' do
      let(:source) { mock_model(Destination, mappable?: true) }
      it { should eq('M') }
    end

    context 'when source is a VlabelMap' do
      let(:source) { mock_model(VlabelMap) }
      it { should eq('O') }
    end

    context 'when source is a MediaFile' do
      let(:source) { mock_model(MediaFile) }

      context "when after_prompt is 'continue'" do
        before { exit.stub(:after_prompt) { 'continue' } }
        it { should eq('5') }
      end

      context "when after_prompt is 'stop'" do
        before { exit.stub(:after_prompt) { 'stop' } }
        it { should eq('P') }
      end

      context "when after_prompt is blank" do
        before { exit.stub(:after_prompt) { "" } }
        it { should eq('P') }
      end
    end
  end

  describe :transfer_lookup do
    subject { exit.transfer_lookup }

    context 'when exit requires a dequeue route' do
      before { exit.stub(requires_dequeue?: true) }
      it { should eq('O') }
    end

    context 'when exit does not require a dequeue route' do
      before { exit.stub(requires_dequeue?: false) }
      it { should eq('') }
    end
  end

  describe :requires_dequeue? do
    context 'when type is Destination' do
      it 'returns true if destination is a queue' do
        exit.stub(:source) { mock_model(Destination, is_queue?: true) }
        exit.requires_dequeue?.should be_true
      end

      it 'returns false if destination is not a queue' do
        exit.stub(:source) { mock_model(Destination, is_queue?: false) }
        exit.requires_dequeue?.should be_false
      end
    end

    context 'when type is not Destination' do
      let(:type) { 'VlabelMap' }

      it 'returns false' do
        exit.requires_dequeue?.should be_false
      end
    end
  end

  describe :== do
    it 'returns true when compared to itself' do
      exit.==(exit).should be_true
    end

    it 'returns true when compared to another exit with the same values' do
      exit2 = exit.dup
      exit.==(exit2).should be_true
    end

    it 'returns false when compared to an exit with different values' do
      exit2 = Exit.new({type: 'Destination', value: 'other', dequeue_value: 'd-value'}, 1234)
      exit.==(exit2).should be_false
    end

    it 'returns false when compared to an object of another class' do
      exit.==(1).should be_false
    end

    it 'is aliased to :eql?' do
      exit2 = exit.dup
      exit.eql?(exit2).should be_true
    end

    it 'is not aliased to :equal?' do
      exit2 = exit.dup
      exit.equal?(exit2).should be_false
    end
  end

  describe :find do
    context 'when type is Destination' do
      it 'searches by Destination.destination and app_id' do
        Destination.should_receive(:find_by_destination_and_app_id)
          .with('value', 1234) { stub }
        exit.send(:find)
      end

      it 'returns a Destination model' do
        Destination.stub(:find_by_destination_and_app_id) { mock_model(Destination) }
        exit.send(:find).should be_a(Destination)
      end
    end

    context 'when type is VlabelMap' do
      let(:type) { 'VlabelMap' }

      it 'searches by VlabelMap.vlabel and app_id' do
        VlabelMap.should_receive(:find_by_vlabel_and_app_id)
          .with('value', 1234) { stub }
        exit.send(:find)
      end

      it 'returns a VlabelMap model' do
        VlabelMap.stub(:find_by_vlabel_and_app_id) { mock_model(VlabelMap) }
        exit.send(:find).should be_a(VlabelMap)
      end
    end

    context 'when type is MediaFile' do
      let(:type) { 'MediaFile' }

      it 'searches by MediaFile.keyword and app_id' do
        MediaFile.should_receive(:find_by_keyword_and_app_id)
          .with('value', 1234) { stub }
        exit.send(:find)
      end

      it 'returns a MediaFile' do
        MediaFile.stub(:find_by_keyword_and_app_id) { mock_model(MediaFile) }
        exit.send(:find).should be_a(MediaFile)
      end
    end
  end
end
