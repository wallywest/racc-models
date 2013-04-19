require 'csv'

class BulkFrontendNumber

  VERIFY_SUBMIT = "Verify File"
  UPLOAD_SUBMIT = "Upload File"
  UPLOAD_TYPE_NEW = "new"
  UPLOAD_TYPE_MOVE = "move"
  VERIFIED_MSG = "Congratulations, your file is verified and is ready to be uploaded.  If you want to quit now, click the 'Cancel' link."
  UPLOADED_MSG = "Congratulations, your numbers have all been uploaded to the specified group.  To view your numbers, click on the group in the menu."
  DB_ERROR_INDICATOR = "Database Error:"
  MAX_NUMBERS = 200
  DB_LENGTH_FUNC = ActiveRecord::Base.connection.adapter_name.upcase == 'MYSQL2' ? "LENGTH" : "LEN"

  attr_accessor :errors, :file_format, :current_user_login

  def initialize(_params)
    @raw_uploaded_file = _params[:uploaded_csv]
    @app_id = _params[:app_id]
    @group_name = _params[:vlabel_group]
    @upload_type = _params[:upload_type]
    @errors = []
    @f_numbers = []
    @new_f_params = {}
    @use_mapped_dnis = (_params[:use_mapped_dnis] ? (_params[:use_mapped_dnis].match(/^(true|1)$/) != nil) : false)
    @current_group_id = _params[:current_group_id]
    @current_group_name = _params[:current_group_name]
  end

  def read_file
    begin
      @f_numbers = CSV.parse(@raw_uploaded_file.read)
    rescue => e
      Rails.logger.error "Error occurred while reading the csv:  #{e.inspect}"
      @errors << "Errors occurred while reading the csv file."
    end
  end

  def set_default_params
    company = Company.find(@app_id.to_i)
    group = Group.first(:conditions => {:app_id => @app_id, :name => @group_name})
    default_cti_routine = group.default_cti_routine_record
    
    base_params = {
      :cti_routine => default_cti_routine.value,
      :modified_by => self.current_user_login
    }
    @new_f_params = base_params.merge(other_group_id_attrs(group))
  end
  
  def other_group_id_attrs(_group)
    existing_vlms = _group.vlabel_maps    
    
    if existing_vlms.size == 0
      return {
        :vlabel_group => _group.name,
        :preroute_group_id => nil, 
        :survey_group_id => 0,
        :geo_route_group_id => 0        
      }
    else
      existing_vlm = existing_vlms[0]
      return {
        :vlabel_group => existing_vlm.vlabel_group,
        :preroute_group_id => existing_vlm.preroute_group_id, 
        :survey_group_id => existing_vlm.survey_group_id,
        :geo_route_group_id => existing_vlm.geo_route_group_id        
      }
    end
  end
  
  def verify_numbers
    message = []

    verify_for_all_types
    
    if @errors.empty?
      case @upload_type
      when UPLOAD_TYPE_NEW
        message << verify_new_numbers
      when UPLOAD_TYPE_MOVE
        message << verify_move_numbers
      end
    end

    return (@errors.empty? ? message : @errors)
  end

  def process_numbers
    message = []

    verify_for_all_types
    
    if @errors.empty?
      case @upload_type
      when UPLOAD_TYPE_NEW
        verify_new_numbers
        message << add_new_numbers if @errors.empty?
      when UPLOAD_TYPE_MOVE
        verify_move_numbers
        message << move_numbers if @errors.empty?
      end
    end
    
    return (@errors.empty? ? message : @errors)
  end

  private
  
  def verify_for_all_types
    if @raw_uploaded_file.nil?
      @errors << "A file was not uploaded.  Please upload a file."
    else
      if @raw_uploaded_file.size > 500000
        @errors << "Your file is over the maximum size of 500KB."
      end
      if self.file_format != 'csv'
        @errors << "Your file must be a .csv file."
      end
    end    
    if @errors.empty?
      read_file 
      @errors << "Your file must have no more than #{MAX_NUMBERS} numbers." if @f_numbers.size > MAX_NUMBERS
      @errors << "Your file does not have any data." if @f_numbers.size == 0
    end
  end

  def verify_new_numbers
    message = ""
    set_default_params
    temp_arr_to_check_dups = []
    @f_numbers.each_with_index do |f_number, index|
      if @use_mapped_dnis
        @errors << "On line #{index + 1}:  There is an incorrect number of data columns." unless [1,2,3].include?(f_number.size)
        vlm = VlabelMap.new(@new_f_params.merge(:vlabel => f_number[0], :mapped_dnis => f_number[1], :description => f_number[2]))
      else
        @errors << "On line #{index + 1}:  There is an incorrect number of data columns." unless [1,2].include?(f_number.size)
        vlm = VlabelMap.new(@new_f_params.merge(:vlabel => f_number[0], :description => f_number[1]))
      end
      vlm.app_id = @app_id # need to assign it this way b/c it's protected
      if !vlm.valid?
        vlm.errors.full_messages.each do |err_msg|
          @errors << "On line #{index + 1}:  #{err_msg}"
        end
      end
      @errors << "On line #{index + 1}: This is a duplicate number." if temp_arr_to_check_dups.index(f_number[0])
      temp_arr_to_check_dups << f_number[0]
    end
    message << VERIFIED_MSG if @errors.empty?
    message
  end

  def verify_move_numbers
    message = ""
    temp_arr_to_check_dups = []
    @f_numbers.each_with_index do |f_number, index|
      if f_number.size == 1
        @errors << "On line #{index + 1}: This number is not 10 digits." unless f_number[0].size == 10
        @errors << "On line #{index + 1}: This is a duplicate number." if temp_arr_to_check_dups.index(f_number[0])
        temp_arr_to_check_dups << f_number[0]
      else
        @errors << "On line #{index + 1}: There is an incorrect number of data columns."
      end
    end

    if @errors.empty?
      vlm_orig = @f_numbers.flatten
      vlm_db = VlabelMap.all(:select => "v.vlabel",
        :from => "racc_vlabel_map v",
        :joins => "INNER JOIN web_groups g ON g.name = (
          CASE WHEN v.vlabel_group LIKE '%_GEO_ROUTE_SUB'
          THEN LEFT(v.vlabel_group, (#{DB_LENGTH_FUNC}(v.vlabel_group) - 14))
          ELSE v.vlabel_group END)",
        :conditions => ["v.app_id = ? AND g.id = ? AND v.vlabel in (?)", @app_id, @current_group_id, vlm_orig]
      ).collect {|vlm| vlm.vlabel}
      
      nbrs_not_in_db = vlm_orig - vlm_db
      
      if nbrs_not_in_db.size > 0
        move_errors = "The following number(s) do not exist in the current group (#{@current_group_name}). They must exist in this group prior to moving.<br/><br/>"
        nbrs_not_in_db.each do |nbr|
          move_errors << "#{nbr}<br/>"
        end
        @errors << move_errors
      end
    end

    message << VERIFIED_MSG if @errors.empty?
    message
  end

  def add_new_numbers
    message = ""
    set_default_params
    @f_numbers.each do |f_number|
      begin
        if @use_mapped_dnis
          vlm = VlabelMap.new(@new_f_params.merge({:vlabel => f_number[0], :mapped_dnis => f_number[1], :description => f_number[2], :modified_time => Time.now.utc}))
        else
          vlm = VlabelMap.new(@new_f_params.merge({:vlabel => f_number[0], :description => f_number[1], :modified_time => Time.now.utc}))
        end
        vlm.app_id = @app_id # need to assign it this way b/c it's protected
        vlm.save!
      rescue => e
        Rails.logger.error "Error adding #{f_number} to #{@group_name}.  Error is:  #{e.inspect}"
        @errors << "#{DB_ERROR_INDICATOR} Error occured while adding #{f_number}."
      end
    end
    message << UPLOADED_MSG if @errors.empty?
    message
  end

  def move_numbers
    message = ""
    begin
      dest_group = Group.first(:conditions => {:app_id => @app_id, :name => @group_name})
      nbr_updated = VlabelMap.update_all({:modified_by => self.current_user_login}.merge(other_group_id_attrs(dest_group)), ["app_id = ? AND vlabel IN (?)", @app_id, @f_numbers.flatten])
      @errors << "#{DB_ERROR_INDICATOR} No numbers were moved." if nbr_updated == 0
    rescue => e
      Rails.logger.error "Error moving numbers to #{@group_name}.  Error is:  #{e.inspect}"
      @errors << "#{DB_ERROR_INDICATOR} Error occurred while moving numbers."
    end
    message << UPLOADED_MSG if @errors.empty?
  end
  
end
