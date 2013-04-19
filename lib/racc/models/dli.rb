  self.table_name = :racc_dli
class Dli < ActiveRecord::Base
  has_many :lis, :dependent => :destroy

  
  oath_keeper
  
  HUMANIZED_ATTRIBUTES = {:value => "Name", :lis => "Trunks"}
  
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  validates_presence_of :app_id, :modified_by, :description, :value
  validates_uniqueness_of :value, :scope => :app_id
  validates_format_of :value, :with => /\A[\*]\Z|\A[\w\s\.-]+\Z/, :message => "may include only letters, numbers, underscores, periods and dashes"
  validates_length_of :value, :description, :maximum => 64
  validates_length_of :lis, :maximum => 50, :message => "may not number more than %{count}"
  validate :li_distribution_total
  
  before_validation :set_app_id, :prepend_dli_to_destinations
  
  def self.searches(app_id, term)
    all_dli_dests = Destination.select(:destination).where(["app_id = ? AND destination_attr = ? AND destination like ?", app_id, "D", "%+%#{term}%"])
    
    trunks_only = []
    all_dli_dests.each do |dest_obj|
      dest = dest_obj.destination
      trunks_only << dest.slice(0..dest.index("+")-1)
    end
    
    dli_ids = Li.select(:dli_id).where(["app_id = ? AND value like ?", app_id, "%#{term}%"]).map(&:dli_id)

    Dli.where(["app_id = ? AND (value LIKE ? OR value IN (?) OR id IN (?))", app_id, "%#{term}%", trunks_only, dli_ids]).uniq
  end
  
  def li_distribution_total
    unless lis.map {|li| li.marked_for_destruction? ? 0 : li.dpct }.reduce {|l, r| l.to_i + r.to_i} == 100
      errors.add('lis', "distribution percentage must add up to exactly 100")
    end
  end

  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
  
  def prepend_dli_to_destinations
    @destinations ||= []
    @destinations.each do |dest|
      dest.destination = "#{self.value}+#{dest.destination}"
    end
  end
  
  accepts_nested_attributes_for :lis, :allow_destroy => true

  before_save :update_modified_time
  after_save :save_destinations
  before_destroy :no_destinations
  
  def update_modified_time
    self.modified_time = Time.now
  end
  
  def dnis_numbers
    Destination.in_dli(value).where(:app_id => app_id).sort do |x, y|
      x.destination <=> y.destination
    end
  end
  
  def dnis_numbers_attributes=(attrs)
    @destinations ||= []
    attrs.each do |id, values|
      dnis = values.delete(:dnis)
      values[:destination] = dnis
      
      object_id = values.delete(:id)
      
      if object_id && Destination.exists?(object_id)
        object = Destination.find(object_id)
        @destinations << object
        destroy_flag = values.delete(:_destroy)
        case destroy_flag
        when 1, '1', true, 'true'
          object.mark_for_destruction
        else
          object.attributes = values
        end
      else
        destroy_flag = values.delete(:_destroy)
        case destroy_flag
        when 1, '1', true, 'true'
          next
        else
          values[:app_id] = ThreadLocalHelper.thread_local_app_id
          values[:destination_attr] = 'D'
          object = Destination.new(values)
          @destinations << object
        end
      end
    end
  end
    
  def destroy_li_children
    self.lis.each do |li|
      li.destroy
    end
  end
  
  def format_for_search
    values = {:name => self.value, :type => "Mega-Trunk", :path => {:method => :edit_dli_path, :ref => self}, :date => self.modified_time, :meta => {:description => self.description}}
    
    class << values
      def path_to_search_result view
        view.send(self[:path][:method], self[:path][:ref])
      end
    end
    
    return values
  end
  
  protected
  def save_destinations
    @destinations.each do |d|
      if d.marked_for_destruction?
        d.destroy
      else
        d.save
      end
    end if @destinations
  end
  
  def no_destinations
    dnis_numbers.size == 0
  end
end
