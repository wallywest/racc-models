require 'spec_helper'

describe ExitSearch do
  describe :all do
    before do
      Company.stub(:find).with(app_id).and_return(company)
      VlabelMap.stub(:search_for).with(app_id, term) { [VlabelMap.new] }
      MediaFile.stub(:search_for).with(app_id, term) { [MediaFile.new] }
    end
    
    let(:company){ FactoryGirl.build(:company, :route_to_options => ROUTE_TO_ALL) }
    let(:app_id) { 1 }
    let(:term) { 'test' }

    context "non-mapped destinations" do
      before do
        Destination.stub(:for_autocomplete).with(app_id, term) { [Destination.new] }
      end
      
      let(:for_mapped) { nil }

      it 'returns an array' do
        ExitSearch.all(app_id, term, for_mapped).should be_a(Enumerable)
      end
  
      it 'concatenates results of different types' do
        ExitSearch.all(app_id, term, for_mapped).should have(3).items
      end
    end
    
    context "mapped destinations" do
      before do
        Location.stub(:for_mapped_dest_autocomplete).with(app_id, term) { [Destination.new, Destination.new] }
      end

      let(:for_mapped) { "true" }

      it "searches for mapped destination specific destinations" do
        ExitSearch.all(app_id, term, "true").should have(4).items 
      end
    end

    context "options available by company flag" do
      subject{ ExitSearch.all(app_id, term) }

      before do
        Destination.stub(:for_autocomplete).with(app_id, term) { [Destination.new] }
        VlabelMap.stub(:search_for).with(app_id, term) { [VlabelMap.new] }
        MediaFile.stub(:search_for).with(app_id, term) { [MediaFile.new] }
      end
      
      it "should search for all types" do
        company.route_to_options = ROUTE_TO_ALL
        should have(3).items
      end

      it "should search for destinations only" do
        company.route_to_options = ROUTE_TO_DEST
        should have(1).item
      end

      it "should search for destinations and vlabels" do
        company.route_to_options = ROUTE_TO_VLM
        should have(2).items
      end

      it "should search for destinations and prompts" do
        company.route_to_options = ROUTE_TO_MEDIA
        should have(2).items
      end
    end
  end

  describe :find do
    let(:app_id) { 1 }
    let(:term) { 'test' }
    let(:company){ FactoryGirl.build(:company, :route_to_options => ROUTE_TO_ALL) }

    before do
      Company.stub(:find).with(app_id).and_return(company)
    end

    context "non-mapped destinations" do
      before do
        Destination.stub(:for_autocomplete).with(app_id, term) { [] }
        VlabelMap.stub(:search_for_exact).with(app_id, term) { [VlabelMap.new] }
        MediaFile.stub(:search_for_exact).with(app_id, term) { [MediaFile.new] }
      end
      
      let(:for_mapped) { nil }

      it 'returns a hash' do
        ExitSearch.find(app_id, term, for_mapped).should be_a(Hash)
      end
  
      it 'returns the first match' do
        ExitSearch.find(app_id, term, for_mapped)['type'].should eq('VlabelMap')
      end
    end

    context "mapped destinations" do
      before do
        Location.stub(:for_mapped_dest_autocomplete).with(app_id, term, true) { [Destination.new] }
        VlabelMap.stub(:search_for_exact).with(app_id, term) { [VlabelMap.new] }
        MediaFile.stub(:search_for_exact).with(app_id, term) { [MediaFile.new] }
      end

      let(:for_mapped) { "true" }

      it "searches for mapped destination specific destinations" do
        ExitSearch.find(app_id, term, for_mapped)['type'].should eq('Destination')
      end
    end

    context "options available by company flag" do
      subject{ ExitSearch.find(app_id, term)['type'] }

      context "when the All flag is set" do
        before do
          company.route_to_options = ROUTE_TO_ALL
        end

        it { finds_dest }
        it { finds_vlabel }
        it { finds_media }
      end

      context "when the Destination flag is set" do
        before do
          company.route_to_options = ROUTE_TO_DEST
        end

        it { finds_dest }
        it { ignores_vlabel }
        it { ignores_media }
      end

      context "when the Vlabel flag is set" do
        before do
          company.route_to_options = ROUTE_TO_VLM
        end

        it { finds_dest }
        it { finds_vlabel }
        it { ignores_media }
      end

      context "when the Media flag is set" do
        before do
          company.route_to_options = ROUTE_TO_MEDIA
        end

        it { finds_dest }
        it { ignores_vlabel }
        it { finds_media }
      end

      def finds_dest
        Destination.stub(:find_valid).with(any_args) { [Destination.new] }
        should eq('Destination')
      end

      def finds_vlabel
        VlabelMap.stub(:search_for_exact).with(any_args) { [VlabelMap.new] }
        should eq('VlabelMap')
      end

      def finds_media
        MediaFile.stub(:search_for_exact).with(any_args) { [MediaFile.new] }
        should eq('MediaFile')
      end

      def ignores_vlabel
        VlabelMap.stub(:search_for_exact).with(any_args) { [VlabelMap.new] }
        should eq(nil)
      end

      def ignores_media
        MediaFile.stub(:search_for_exact).with(any_args) { [MediaFile.new] }
        should eq(nil)
      end
    end
  end

  describe :format_as_autocomplete do
    context 'when results are empty' do
      it 'returns one result' do
        formatted_results = ExitSearch.format_as_autocomplete([])
        formatted_results.should have(1).item
      end

      it 'returns a No Results Found entry' do
        formatted_results = ExitSearch.format_as_autocomplete([])
        formatted_results.first['label'].should eq('No results found')
      end
    end

    context 'when there are several results' do
      let(:results) { [Destination.new, VlabelMap.new] }

      it 'returns the same number of results' do
        formatted_results = ExitSearch.format_as_autocomplete(results)
        formatted_results.should have(results.size).items
      end

      it 'returns a hash for each result' do
        formatted_results = ExitSearch.format_as_autocomplete(results)
        formatted_results.each do |r|
          r.should be_a(Hash)
        end
      end
    end
  end
end
