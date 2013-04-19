class CacheUrl < ActiveRecord::Base
  self.table_name = "web_cache_urls"
  
  
  oath_keeper
  
  has_many :cache_url_xrefs
  has_many :companies, :through => :cache_url_xrefs

  validates_presence_of :address, :cache_table_group_id, :port
end
