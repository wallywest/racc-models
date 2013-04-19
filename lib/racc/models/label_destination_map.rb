class LabelDestinationMap < ActiveRecord::Base
  self.table_name = 'racc_label_destination_map'
  
  belongs_to :vlabel_map
  belongs_to :mapped_destination, :class_name => 'Destination', :foreign_key => :mapped_destination_id
  belongs_to :exit, :polymorphic => true

  scope :with_associations, includes(:vlabel_map, :mapped_destination, :final_destination)
  scope :defaults_only, where("vlabel_map_id IS NULL")
  scope :routed_to, lambda {|type| where(exit_type: type)}
  scope :for, lambda {|app_id| where(app_id: app_id)}

  validates_presence_of :app_id, :mapped_destination_id, :exit_id, :exit_type
  
  PER_PAGE = 50
  ALL_OPTION = "all_groups_in_dropdown"
end
