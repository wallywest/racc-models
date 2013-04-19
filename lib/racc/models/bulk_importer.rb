require 'csv'

class BulkImporter
  
  attr_reader :errors

  def initialize(file)
    begin
      @rows = CSV.parse(file.read, :headers => :first_row)
    rescue CSV::MalformedCSVError => e
      raise DataFormatError.new("Unable to parse contents of file.  Maybe it was an invalid format, or there was a typo?")
    end
    @errors = []
  end
  
  def process
    objects = []
    @rows.each_with_index do |row, i|
      attrs = row.to_hash
      type = attrs.delete 'type'
      
      csv_line_number = i + 2
      begin
        klass = type.classify.constantize
      rescue => e
        @errors << ValidationError::Base.new(csv_line_number, "Cannot import data of the specified type because it is invalid : #{type}")
        next
      end
        
      unless allowed_types.include? klass
        @errors << ValidationError::Base.new(csv_line_number, "Type not permitted for bulk import : #{type}")
        next
      end
      
      objects << {:record => klass.new(attrs), :line_number => csv_line_number}
      
    end
    
    ActiveRecord::Base.transaction do
      objects.each do |o|
        object = o[:record]
        object.modified_time = Time.now if object.respond_to?(:modified_time)
        object.modified_by = "racc_admin" if object.respond_to?(:modified_by)
        begin
          if object.valid? 
            object.save 
          else
            object.errors.each_full do |msg|
              @errors << ValidationError::Base.new(o[:line_number], msg)
            end
          end
        rescue
          @errors << ValidationError::Base.new(o[:line_number], "An error occurred while trying to save this record.")
        end
      end
      raise ActiveRecord::Rollback unless @errors.empty?
    end
    
    return objects.map{|o| o[:record]}
  end
  
  private
  
  def allowed_types
    [Destination, VlabelMap, TransferMap, Operation, DestinationProperty, PrerouteGroup, SurveyGroup, User]
  end
  
end

module ValidationError
  class Base
    attr_accessor :line_number, :message
    
    def initialize(line_number = nil, message = nil)
      @line_number = line_number
      @message = message
    end
  end
end

class DataFormatError < Exception
  
end
