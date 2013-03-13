module Racc::Models
class Group < Sequel::Model(:web_groups)
  one_to_many :vlabel_maps, :dataset=>(proc do |r|
    r.associated_dataset.where(:app_id => self.app_id).
      where(:vlabel_group => name).or(:vlabel_group => "#{name}_GEO_ROUTE_SUB")
  end)

  def self.frontend_groups(app_id)
    where(:category => "f").where(:app_id => app_id)
  end
end
end
