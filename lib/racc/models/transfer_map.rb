class TransferMap < ActiveRecord::Base
  self.table_name = "racc_transfer_map"
  self.primary_key = :transfer_map_id
  
  
  oath_keeper
  
  HUMANIZED_ATTRIBUTES = {:vlabel => "Default Route", :transfer_string => "Speed Dial String"}
  
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  attr_protected :app_id
  
  validates_presence_of :app_id
  validates_presence_of :transfer_string, :message => "cannot be blank."
  validates_presence_of :vlabel, :message => "for the transfer digits must be provided"
  validates_uniqueness_of :transfer_string, :scope => :app_id
  validate :route_exists
  
  scope :containing, lambda {|app_id, transfer_string| where("app_id = :app_id AND transfer_string LIKE :transfer_string", {:app_id => app_id, :transfer_string => '%' + transfer_string + '%'}).order("transfer_string ASC").limit(10) }
  scope :searches, lambda {|app_id, term| where(["app_id = ? AND (transfer_string LIKE ? OR vlabel LIKE ?)", app_id, "%#{term}%", "%#{term}%"])}
  
  before_validation :set_app_id
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
  
  def route_exists
    unless RaccRoute.exists?(:route_name => self.vlabel, :app_id => self.app_id)
      errors.add('vlabel', "must point to a valid route")
    end
  end

  def format_for_search
    values = {:name => self.transfer_string, :type => "Speed Dial", :path => {:method => :speed_dial_path, :ref => self.id}, :date => self.modified_time, :meta => {:default_route => self.vlabel}}
    
    class << values
      def path_to_search_result view
        view.send(self[:path][:method], self[:path][:ref])
      end
    end
    
    return values
  end
  
  def self.with_vlabel_maps_and_active_packages(_app_id, _limit=nil, _transfer_string=nil)
    db_length = ActiveRecord::Base.connection.adapter_name.upcase =~ /MYSQL2/ ? "LENGTH" : "LEN"
    tm_query = TransferMap.select("DISTINCT tm.*, vlm.vlabel_map_id as vlabel_map_id, p.id as active_package_id, 
    (CASE WHEN vlm.vlabel_group like '%_GEO_ROUTE_SUB' THEN (SELECT id from web_groups where app_id=#{_app_id} and name=LEFT(vlm.vlabel_group, (#{db_length}(vlm.vlabel_group)-14)))
    WHEN vlm.vlabel_group not like '%_GEO_ROUTE_SUB' THEN g.id END) as group_id")
    tm_query = tm_query.from("racc_transfer_map tm")
    tm_query = tm_query.joins("
      INNER JOIN racc_vlabel_map vlm ON vlm.app_id = tm.app_id AND vlm.vlabel = tm.vlabel 
      INNER JOIN racc_route rr ON rr.app_id = vlm.app_id AND rr.route_name = vlm.vlabel 
      LEFT OUTER JOIN web_groups g ON g.app_id = vlm.app_id AND g.name = vlm.vlabel_group
      INNER JOIN web_packages p ON p.app_id = vlm.app_id AND p.vlabel_map_id = vlm.vlabel_map_id")
    tm_query = tm_query.where("tm.app_id = ? AND p.active = ?", _app_id, true)
    
    if _transfer_string
      tm_query = tm_query.where("tm.transfer_string = ?", _transfer_string)
    end

    # NOTE: There is a bug in SQL Server Adapter > 3.0 that adds a "group by" clause to this query when the "limit" clause is added.
    # So, we are limiting the number in the controller (speed_dials_controller)
    if _limit
      tm_query = tm_query.order("tm.modified_time DESC")
    else
      tm_query = tm_query.order("tm.transfer_string")
    end
    
    tm_query.all
  end
end
