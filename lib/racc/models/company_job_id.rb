class CompanyJobId < ActiveRecord::Base
  self.table_name = :web_company_job_ids
  belongs_to :company
  
  validates_numericality_of :job_id, :only_integer => true
  validates_presence_of :company_id
  validate  :validate_length
  
  def validate_length
    # Can't use validates_length_of on numbers b/c it returns the storage size in bytes instead of the length of the number.
    unless self.job_id.to_i >= 100 && self.job_id.to_i <= 99999
      errors.add("job_id", "must be between 3 and 5 digits long")
    end
  end
end
