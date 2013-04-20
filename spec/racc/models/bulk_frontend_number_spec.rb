require 'spec_helper'
require 'csv'

describe BulkFrontendNumber do
  before do
    @csv_file = mock(:csv)
  end

  describe "verify_numbers" do
    it "returns an error if the file is nil" do
      @bfn = BulkFrontendNumber.new({})
      @bfn.verify_numbers
      @bfn.errors.should == ["A file was not uploaded.  Please upload a file."]
    end

    context "validations on a bad file" do
      before do
        base_params = {
          :app_id => 1,
          :uploaded_csv => @csv_file,
          :use_mapped_dnis => "false"
        }
        @bfn = BulkFrontendNumber.new(base_params)
        @bfn.current_user_login = 'test_admin'
      end

      it "returns a size error if the csv's size is bigger than 500KB" do
        @bfn.file_format = "csv"
        @csv_file.should_receive(:size).and_return 500001
        @bfn.verify_numbers
        @bfn.errors.should == ["Your file is over the maximum size of 500KB."]
      end

      it "returns an error if the file format is not csv" do
        @csv_file.should_receive(:size).and_return 1
        @bfn.verify_numbers
        @bfn.errors.should == ["Your file must be a .csv file."]
      end

      context "validations after reading the bad file" do
        before do
          @bfn.file_format = "csv"
          @csv_file.should_receive(:size).and_return 1
          @csv_file.stub!(:read)
        end

        it "returns an error if the file has more numbers than the max" do
          f_numbers = []
          CSV.should_receive(:parse).with(any_args).and_return f_numbers
          f_numbers.should_receive(:size).twice.and_return BulkFrontendNumber::MAX_NUMBERS + 1
          @bfn.verify_numbers
          @bfn.errors.should == ["Your file must have no more than #{BulkFrontendNumber::MAX_NUMBERS} numbers."]
        end

        it "returns an error if the file is blank" do
          CSV.should_receive(:parse).with(any_args).and_return []
          @bfn.verify_numbers
          @bfn.errors.should == ["Your file does not have any data."]
        end
      end
    end

    context "verifying a valid file" do
      context "new numbers" do
        before do
          @company = FactoryGirl.build(:company)
          @group = FactoryGirl.create(:group, :category => 'f', :group_default => false)
          @mock_cti = mock(:cti_routine)

          Company.should_receive(:find).any_number_of_times.with(any_args).and_return @company
          Group.should_receive(:first).with(any_args).and_return @group
          @group.should_receive(:default_cti_routine_record).and_return @mock_cti
          @mock_cti.should_receive(:value)

          base_params = {
            :app_id => @company.id,
            :vlabel_group => @group.name,
            :uploaded_csv => @csv_file,
            :upload_type => BulkFrontendNumber::UPLOAD_TYPE_NEW,
            :use_mapped_dnis => "false"
          }

          @bfn = BulkFrontendNumber.new(base_params)
          @bfn.file_format = "csv"
          @bfn.current_user_login = 'test_admin'
          @csv_file.should_receive(:size).and_return 1
          @csv_file.stub!(:read)
        end

        it "returns no errors for a valid list of numbers and descriptions" do
          good_f_numbers = [['1234567890'], ['2223334444', 'hello testing']]
          CSV.should_receive(:parse).with(any_args).and_return good_f_numbers
          @bfn.verify_numbers
          @bfn.errors.should == []
        end

        it "returns errors for an invalid list of numbers" do
          bad_f_numbers = [['blah'], [], ['12345678901']]
          CSV.should_receive(:parse).with(any_args).and_return bad_f_numbers
          @bfn.verify_numbers
          @bfn.errors.should == [
            "On line 1:  Number must be exactly 10 digits",
            "On line 2:  There is an incorrect number of data columns.",
            "On line 2:  Number must be exactly 10 digits",
            "On line 3:  Number must be exactly 10 digits"
          ]
        end
      end
      
      context "new numbers with mapped dnis numbers" do
        before do
          @company = FactoryGirl.build(:company)
          @group = FactoryGirl.create(:group, :category => 'f', :group_default => false)
          @mock_cti = mock(:cti_routine)

          Company.should_receive(:find).any_number_of_times.with(any_args).and_return @company
          Group.should_receive(:first).with(any_args).and_return @group
          @group.should_receive(:default_cti_routine_record).and_return @mock_cti
          @mock_cti.should_receive(:value)

          base_params = {
            :app_id => @company.id,
            :vlabel_group => @group.name,
            :uploaded_csv => @csv_file,
            :upload_type => BulkFrontendNumber::UPLOAD_TYPE_NEW,
            :use_mapped_dnis => "true"
          }

          @bfn = BulkFrontendNumber.new(base_params)
          @bfn.file_format = "csv"
          @bfn.current_user_login = 'test_admin'
          @csv_file.should_receive(:size).and_return 1
          @csv_file.stub!(:read)
        end
        
        it "returns no errors for a valid list of numbers, mapped dnis numbers, and descriptions" do
          good_f_numbers = [['1234567890'], ['2223334444', '12345', 'hello testing']]
          CSV.should_receive(:parse).with(any_args).and_return good_f_numbers
          @bfn.verify_numbers
          @bfn.errors.should == []
        end

        it "returns errors for an invalid list of numbers" do
          bad_f_numbers = [['blah'], ['1234567890', 'description in wrong place'], ['1234567893','123']]
          CSV.should_receive(:parse).with(any_args).and_return bad_f_numbers
          @bfn.verify_numbers
          @bfn.errors.should == [
            "On line 1:  Number must be exactly 10 digits", 
            "On line 2:  Mapped DNIS must be a number between 4 and 14 digits in length", 
            "On line 3:  Mapped DNIS must be a number between 4 and 14 digits in length"
          ]
        end
      end

      context "move numbers" do
        before do
          @group = FactoryGirl.create(:group, :category => 'f', :group_default => false)

          base_params = {
            :app_id => @group.app_id,
            :vlabel_group => 'new_group',
            :uploaded_csv => @csv_file,
            :upload_type => BulkFrontendNumber::UPLOAD_TYPE_MOVE,
            :use_mapped_dnis => "false",
            :current_group_id => @group.id,
            :current_group_name => @group.name_for_display
          }

          @bfn = BulkFrontendNumber.new(base_params)
          @bfn.file_format = "csv"
          @bfn.current_user_login = 'test_admin'
          @csv_file.should_receive(:size).and_return 1
          @csv_file.stub!(:read)
        end

        it "returns no errors for a valid list of numbers" do
          FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => '1112221111')
          FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => '2223332222')
          good_f_numbers = [['1112221111'], ['2223332222']]
          CSV.should_receive(:parse).with(any_args).and_return good_f_numbers
          @bfn.verify_numbers
          @bfn.errors.should == []
        end

        it "returns errors for invalid numbers" do
          bad_f_numbers = [['5556665555'], ['8887778888']]
          CSV.should_receive(:parse).with(any_args).and_return bad_f_numbers
          @bfn.verify_numbers
          @bfn.errors.should == ["The following number(s) do not exist in the current group (#{@group.name_for_display}). They must exist in this group prior to moving.<br/><br/>5556665555<br/>8887778888<br/>"]
        end
        
        it "returns an error if a number is in the database, but in a different group" do
          another_group = FactoryGirl.create(:group, :category => 'f', :group_default => false)
          FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => '5556665555')
          FactoryGirl.create(:vlabel_map, :vlabel_group => another_group.name, :vlabel => '7778887777')
          soso_f_numbers = [['5556665555'], ['7778887777']]
          CSV.should_receive(:parse).with(any_args).and_return soso_f_numbers
          @bfn.verify_numbers
          @bfn.errors.should == ["The following number(s) do not exist in the current group (#{@group.name_for_display}). They must exist in this group prior to moving.<br/><br/>7778887777<br/>"]
        end
      end
    end # end context verifying a valid file
  end # end context verify_numbers

  describe "process_numbers" do
    context "new numbers" do
      before do
        @company = FactoryGirl.build(:company)
        @group = FactoryGirl.create(:group, :category => 'f', :group_default => false)
        @mock_cti = mock(:cti_routine)

        Company.should_receive(:find).any_number_of_times.with(any_args).and_return @company
        Group.should_receive(:first).with(any_args).any_number_of_times.and_return @group
        @group.should_receive(:default_cti_routine_record).any_number_of_times.and_return @mock_cti
        @mock_cti.should_receive(:value).any_number_of_times

        base_params = {
          :app_id => @company.id,
          :vlabel_group => @group.name,
          :uploaded_csv => @csv_file,
          :upload_type => BulkFrontendNumber::UPLOAD_TYPE_NEW,
          :use_mapped_dnis => "false"
        }

        @bfn = BulkFrontendNumber.new(base_params)
        @bfn.file_format = "csv"
        @bfn.current_user_login = 'test_admin'
        @csv_file.stub!(:read)
        @csv_file.should_receive(:size).and_return 1
      end

      it "uploads the numbers" do
        good_f_numbers = [['6663336666'], ['7778887777']]
        CSV.should_receive(:parse).with(any_args).and_return good_f_numbers
        @bfn.process_numbers
        VlabelMap.all(:conditions => ["vlabel in (?)", good_f_numbers.flatten]).size.should == 2
      end

      it "returns an error if an error occurs during verifying while importing" do
        bad_f_numbers = [['22233355552'], ['abc']]
        CSV.should_receive(:parse).with(any_args).and_return bad_f_numbers
        @bfn.process_numbers
        @bfn.errors.should == [
          "On line 1:  Number must be exactly 10 digits", 
          "On line 2:  Number must be exactly 10 digits"
        ]
      end
    end
    
    context "new numbers with mapped dnis" do
      before do
        @company = FactoryGirl.build(:company)
        @group = FactoryGirl.create(:group, :category => 'f', :group_default => false)
        @mock_cti = mock(:cti_routine)

        Company.should_receive(:find).any_number_of_times.with(any_args).and_return @company
        Group.should_receive(:first).with(any_args).any_number_of_times.and_return @group
        @group.should_receive(:default_cti_routine_record).any_number_of_times.and_return @mock_cti
        @mock_cti.should_receive(:value).any_number_of_times

        base_params = {
          :app_id => @company.id,
          :vlabel_group => @group.name,
          :uploaded_csv => @csv_file,
          :upload_type => BulkFrontendNumber::UPLOAD_TYPE_NEW,
          :use_mapped_dnis => "true"
        }

        @bfn = BulkFrontendNumber.new(base_params)
        @bfn.file_format = "csv"
        @bfn.current_user_login = 'test_admin'
        @csv_file.stub!(:read)
        @csv_file.should_receive(:size).and_return 1
      end

      it "uploads the numbers" do
        good_f_numbers = [['6663336666'], ['7778887777','888777'], ['3674877444','','hello']]
        CSV.should_receive(:parse).with(any_args).and_return good_f_numbers
        @bfn.process_numbers
        VlabelMap.all(:conditions => ["vlabel in (?)", good_f_numbers.flatten]).size.should == 3
      end

      it "returns an error if an error occurs during verifying while importing" do
        bad_f_numbers = [['2223335555','abc'], ['abc']]
        CSV.should_receive(:parse).with(any_args).and_return bad_f_numbers
        @bfn.process_numbers
        @bfn.errors.should == [
          "On line 1:  Mapped DNIS must be a number between 4 and 14 digits in length", 
          "On line 2:  Number must be exactly 10 digits"
        ]
      end
    end
    
    context "move numbers" do
      before do
        @group = FactoryGirl.create(:group, :category => 'f', :group_default => false)
        @another_group = FactoryGirl.create(:group, :category => 'f', :group_default => false, :name => 'another_group')

        base_params = {
          :app_id => @group.app_id,
          :vlabel_group => @another_group.name,
          :uploaded_csv => @csv_file,
          :upload_type => BulkFrontendNumber::UPLOAD_TYPE_MOVE,
          :use_mapped_dnis => "false",
          :current_group_id => @group.id,
          :current_group_name => @group.name_for_display
        }

        @bfn = BulkFrontendNumber.new(base_params)
        @bfn.file_format = "csv"
        @bfn.current_user_login = 'test_admin'
        @csv_file.stub!(:read)
        @csv_file.should_receive(:size).and_return 1
      end
      
      it "moves the numbers" do
        FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => '4449998888')
        FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => '3339992222')
        good_f_numbers = [['4449998888'], ['3339992222']]
        CSV.should_receive(:parse).with(any_args).and_return good_f_numbers
        @bfn.process_numbers
        VlabelMap.all(:conditions => ["vlabel in (?) AND vlabel_group = ?", good_f_numbers.flatten, @another_group.name]).size.should == 2
      end
      
      it "returns an error if an error occurs during verifying while moving" do
        bad_f_numbers = [['3336667777'], ['9990008888']]
        CSV.should_receive(:parse).with(any_args).and_return bad_f_numbers
        @bfn.process_numbers
        @bfn.errors.should == ["The following number(s) do not exist in the current group (#{@group.name_for_display}). They must exist in this group prior to moving.<br/><br/>3336667777<br/>9990008888<br/>"]
      end
      
      it "returns a db error if an error occurs while moving" do
        FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => '4449998888')
        FactoryGirl.create(:vlabel_map, :vlabel_group => @group.name, :vlabel => '3339992222')
        good_f_numbers = [['4449998888'], ['3339992222']]
        CSV.should_receive(:parse).with(any_args).and_return good_f_numbers
        VlabelMap.should_receive(:update_all).with(any_args).and_return 0
        @bfn.process_numbers        
        @bfn.errors.should == ["Database Error: No numbers were moved."]
      end
    end
  end # end process_numbers
end
