require 'spec_helper'

describe PrerouteConfig do

  let(:app_id) { 1 }

  describe "for" do
  end

  describe "new" do
    it "should call setup_vars" do
      PrerouteConfig.any_instance.should_receive(:setup_vars)
      PrerouteConfig.new(app_id)
    end

    it "should set the app_id" do
      config = PrerouteConfig.new(app_id)

      expect(config.app_id).to eq(app_id)
    end

  end

  describe "setup_vars" do
    it "should find all groups with preroutes" do
      mock_relation = mock(:relation)
      Group.should_receive(:groups_with_preroutes).with(app_id).and_return(mock_relation)
      mock_relation.should_receive(:select)

      PrerouteConfig.new(app_id)
    end

    it "should find all current preroute_selections" do
      PrerouteSelection.should_receive(:groups_and_vlabels).with(app_id,true)

      PrerouteConfig.new(app_id)
    end
  end

  describe "helper methods" do
    before(:each) do
      @f_group = FactoryGirl.create(:frontend_group)
      @b_group = FactoryGirl.create(:with_preroute)
      @preroute_group = FactoryGirl.create(:preroute_group)

      @vlm0 = FactoryGirl.create(:vlabel_map, :vlabel_group => @f_group.name,
                                 :vlabel => "1234567890",
                                 :preroute_group_id => @preroute_group.preroute_group_id)
      @vlm1 = FactoryGirl.create(:vlabel_map, :vlabel_group => @b_group.name,
                    :preroute_group_id => @preroute_group.preroute_group_id)
      
      @vlm2 = FactoryGirl.create(:vlabel_map, :vlabel_group => @b_group.name,
                    :preroute_group_id => @preroute_group.preroute_group_id)

      @f_group.vlabel_maps = [@vlm0]
      @b_group.vlabel_maps = [@vlm1,@vlm2]

      @ps0 = FactoryGirl.create(:preroute_selection, :group => @f_group)
      @ps1 = FactoryGirl.create(:preroute_selection, :vlabel_map => @vlm1)
      @ps2 = FactoryGirl.create(:preroute_selection, :vlabel_map=> @vlm2)
    end

    let(:config) {PrerouteConfig.new(1)}

    it "#many_to_one_groups" do
      expect(config.many_to_one_groups).to eq([@f_group])
    end

    it "#one_to_one_groups" do
      expect(config.one_to_one_groups).to eq([@b_group])
    end

    it "#selected_vlabels" do
      expect(config.selected_vlabels).to eq([@ps1,@ps2])
    end

    it "#selected_groups" do
      expect(config.selected_groups).to eq([@ps0])
    end

    it "#selected_groups_for_vlabels" do
      expect(config.selected_groups_for_vlabels).to eq([@b_group.name])
    end

    it "#selected_preroute_ids_for_groups" do
      expect(config.preroute_ids_for_groups).to eq({@f_group.id => @preroute_group.id, @b_group.id => @preroute_group.id})
    end
  end


  describe "update" do
    before(:each) do
      @config = PrerouteConfig.new(1)

      @config.stub!(:selected_groups_ids).and_return([2,3])
      @config.stub!(:selected_vlabels_ids).and_return([4,5])
    end

    describe "find_delete_keys" do

      it "should return subset of ids" do
        param = {"2" => "1"}
        out = @config.deleted_keys([2,3],param)

        expect(out).to eq([3])
      end

      it "should return all of ids with blank" do
        out = @config.deleted_keys([2,3],{})
        expect(out).to eq([2,3])
      end
    end

    describe "destroyed_unused" do
      it "should destroy correct PrerouteSelections" do
        
        gparam = {"2" => "1"}
        vparam = {"4" => "1"}
        
        PrerouteSelection.should_receive(:destroy_all).with(["vlabel_map_id IN (?) AND app_id = ?", [5], 1]).once
        PrerouteSelection.should_receive(:destroy_all).with(["group_id IN (?) AND app_id = ?", [3], 1]).once

        @config.destroy_unused(gparam,vparam)
      end
    end
    
    describe "create_or_update" do
      before(:each) do
        @ps1 = FactoryGirl.create(:preroute_selection, :group_id => "6")
        @ps2 = FactoryGirl.create(:preroute_selection, :vlabel_map_id => "3")
        @gparam = {"6" => "1", "3" => "3"}
        @vparam = {"4" => "2", "3" => "2"}
      end

      it "should find a PrerouteSelection or create a new one" do
        query = mock(ActiveRecord::Relation)
        query2 = mock(ActiveRecord::Relation)
        pg = mock(:preroute_group).as_null_object

        PrerouteSelection.should_receive(:where).with({:app_id => app_id, :group_id => "6", :vlabel_map_id => nil}).once.and_return(query)
        PrerouteSelection.should_receive(:where).with({:app_id => app_id, :group_id => "3", :vlabel_map_id => nil}).once.and_return(query)

        query.should_receive(:first_or_create).with({:preroute_grouping_id => "1"}).once.and_return(pg)
        query.should_receive(:first_or_create).with({:preroute_grouping_id => "3"}).once.and_return(pg)

        PrerouteSelection.should_receive(:where).with({:app_id => app_id, :group_id => nil, :vlabel_map_id => "4"}).once.and_return(query)
        PrerouteSelection.should_receive(:where).with({:app_id => app_id, :group_id => nil, :vlabel_map_id => "3"}).once.and_return(query)

        query.should_receive(:first_or_create).with({:preroute_grouping_id => "2"}).twice.and_return(pg)

        @config.create_or_update(@gparam,@vparam)
      end

      it "should not update if params are empty" do
        PrerouteSelection.should_not_receive(:where)

        @config.create_or_update({},{})
      end

      it "should save when preroute_grouping_id is nil" do
        query = mock(ActiveRecord::Relation)
        pg = mock(:pg, {:preroute_grouping_id => nil})

        PrerouteSelection.stub!(:where).and_return(query)
        query.stub!(:first_or_create).and_return(pg)

        pg.should_receive(:preroute_grouping_id=).with("1").once
        pg.should_receive(:save)

        @config.create_or_update({"3" => "1"},{})
      end

      it "should  save when preroute_grouping_id has changed" do
        query = mock(ActiveRecord::Relation)
        pg = mock(:pg, {:preroute_grouping_id => 3})

        PrerouteSelection.stub!(:where).and_return(query)
        query.stub!(:first_or_create).and_return(pg)

        pg.should_receive(:preroute_grouping_id=).with("1").once
        pg.should_receive(:save)

        @config.create_or_update({"3" => "1"},{})
      end

      it "should not save when preroute_grouping_id is the same" do
        query = mock(ActiveRecord::Relation)
        pg = mock(:pg, {:preroute_grouping_id => 1})

        PrerouteSelection.stub!(:where).and_return(query)
        query.stub!(:first_or_create).and_return(pg)

        pg.should_not_receive(:preroute_grouping_id=)
        pg.should_not_receive(:save)

        @config.create_or_update({"3" => "1"},{})
      end

    end
  end
end
