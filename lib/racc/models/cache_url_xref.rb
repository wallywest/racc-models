class CacheUrlXref < ActiveRecord::Base
  self.table_name = :web_cache_urls_xref

  oath_keeper

  belongs_to :company, :inverse_of => :cache_url_xrefs, :foreign_key => :app_id
  belongs_to :cache_url

  validates_uniqueness_of :cache_url_id, :scope => :app_id
end
