require 'spec_helper'

describe Page do
  
  before(:each) do
    @page = FactoryGirl.create(:page)
  end
  
  describe "validations" do
    it "should not be valid if the name is blank" do
      @page.name = ''
      @page.should_not be_valid
    end
  end
  
  describe "#replace_placeholders" do
    before(:each) do
      @page_child = FactoryGirl.build(:page, :name => 'test_page,name', :url => '/test_pages/id', :controller_action => 'test_pages/show', :placeholder => 1, :parent_id => @page.id)
      Test.should_receive(:find).with(any_args).and_return({:name => 'hello world'})
      @params = {:id => 3, :controller => 'test_pages', :action => 'show'}
      @objects = {:test_page => Test}
    end
    
    it "should replace the 'id' from the url with an id from the 'params' hash" do
      @page_child.replace_placeholders(@params, @objects)
      @page_child.url.should == '/test_pages/3/'
    end
    
    it "should replace the page's name with a name from the Model passed in the 'objects' hash" do
      @page_child.replace_placeholders(@params, @objects)
      @page_child.name.should == 'hello world'
    end
  end
  
  describe "#create_ancestors" do
    before(:each) do
      @page_new = FactoryGirl.build(:page, :name => 'New', :controller_action => 'controller/new')
      @page_edit = FactoryGirl.build(:page, :name => 'Edit', :controller_action => 'controller/edit')
      @controller = 'test_pages'
    end
    
    it "should set the parent_id to the id of the index page for the passed in controller when the action is 'new'" do
      @page_new.create_ancestors(@controller, 'new', '')
      @page_new.parent_id.should == @page.id
    end
    
    it "should set the parent_id to the id of the index page for the passed in controller when the action is 'edit'" do
      @page_edit.create_ancestors(@controller, 'edit', '')
      @page_edit.parent_id.should == @page.id
    end
    
    it "should set the parent_id to the id of the show page for the passed in controller when the action is 'copy'" do
      page_copy = FactoryGirl.build(:page, :name => 'Copy', :controller_action => 'controller/copy')
      page_show = FactoryGirl.create(:page, :name => 'Show Page', :controller_action => 'test_pages/show_item')
      page_copy.create_ancestors(@controller, 'copy', '')
      page_copy.parent_id.should == page_show.id
    end
    
    it "should set the parent_id to the id of the default index page if the default value is '/d'" do
      page = FactoryGirl.create(:page, :controller_action => 'test_pages/index/d')
      @page_new.create_ancestors(@controller, 'new', '/d')
      @page_new.parent_id.should == page.id
    end
  end
end
