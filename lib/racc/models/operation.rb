class Operation < ActiveRecord::Base
  self.table_name = "racc_op"
  self.primary_key = :op_id

  belongs_to :company, :foreign_key => "app_id"
  has_one :group, :dependent => :destroy

  attr_protected :app_id

  validates_presence_of :vlabel_group
  validates_uniqueness_of :vlabel_group, :scope => :app_id

  
  oath_keeper :meta => [[:group,:display_name]]

  before_validation :set_app_id
  before_save :update_modified_time
  
  MANY_TO_ONE_GEO_OP = 20
  ONE_TO_ONE_GEO_OP = 16

  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end

  def update_modified_time
    self.modified_time = Time.zone.now
  end

  def operation_type
    OperationType.first(:conditions => {:number => self.operation})
  end

  def newop_rec_changed?(new_newop_rec)
    self.newop_rec != new_newop_rec
  end

  def self.current_f_default_vlabels(_app_id)
    Operation.all(
      :select => "DISTINCT racc_op.newop_rec",
      :joins => "INNER JOIN web_groups ON web_groups.name = racc_op.vlabel_group",
      :conditions => ["racc_op.app_id = ? AND web_groups.category = ? AND web_groups.group_default = ?", _app_id, 'f', false]
    ).collect { |op| op.newop_rec }
  end
  
  def self.update_newop_on_geo_op(group, operation_params, app_id)
    Operation.update_all({:newop_rec => operation_params[:newop_rec]}, ["app_id = ? and vlabel_group = ?", app_id, "#{group.name}_GEO_ROUTE_SUB"]) if operation_params
  end
end
