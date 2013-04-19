require 'digest/sha1'

class User < ActiveRecord::Base
  belongs_to :company, :foreign_key => "app_id"
  has_many :user_companies, :dependent => :destroy
  has_many :companies, :through => :user_companies

  self.table_name = "web_users" 
  
   :except => [:last_request_at, :updated_at, :perishable_token, :persistence_token, :cryped_password, :current_login_at, :login_count]
  oath_keeper :ignore => [:login_count, :current_login_ip, :last_login_ip]

  has_and_belongs_to_many :business_units, :join_table => :web_business_units_users
  has_and_belongs_to_many :user_groups
  has_many  :audit_trails
  belongs_to :admin_report
  
  attr_protected :app_id
    
  validates_presence_of :user_groups, :message => "cannot be empty."
  validates_presence_of :first_name, :last_name
  validates_length_of :login, :maximum => 12
  validates_length_of :first_name, :maximum => 12
  validates_format_of :first_name, :with => /\A[A-Z]+\Z/i, :allow_blank => true
  validates_format_of :last_name, :with => /\A[A-Z]+\Z/i, :allow_blank => true
  validates_length_of :last_name, :maximum => 24
  
  acts_as_authentic do |c|
    c.logged_in_timeout = 1.hour
    c.validates_uniqueness_of_email_field_options = {:case_sensitive => false} 
    c.validates_uniqueness_of_login_field_options = {:case_sensitive => false}
    c.validates_length_of_password_field_options = {:within => 8..40, :if => :password_required? }  
    c.validates_format_of_password_field_options = {:with => /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[\!\@\#\$\~\`\%\^\&\*\(\)\_\-\+\=\{\}\[\]\:\;\'\"\<\,\>\.\?])([\x20-\x7E]){8,}$/, :message => "must have at least one lowercase letter, one uppercase letter, one number, and one special character.", :if => :password_required?}
    c.validates_format_of_email_field_options = {:with => Authlogic::Regex.email, :message => " should be of the format \"user@example.com\"."}
  end

  before_validation :set_app_id
  before_destroy :delete_group_associations
  
  def set_app_id
    self.app_id ||= ThreadLocalHelper.thread_local_app_id
  end
  
  before_save :encrypt_password
  
  #CODE FOR NEW ROLES AND USER MGMT
  def deliver_password_reset_instructions
    begin
      reset_perishable_token!
      PasswordMailer.password_reset_instructions(self).deliver
      return true
    rescue => e
      return false
    end
  end
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  def permissions=(permissions)
    permissions.each do |attributes|
      permission.build(attributes)
    end
  end
  
  def member_of?(group_name)
    self.user_groups.any? {|group| group.name == group_name}
  end
  
  def role?(role)
    role_name = role.to_s.titleize
    return member_of? role_name
  end
  
  def role
    return "" if self.user_groups.blank?
    self.user_groups.first.name
  end
  
  def member_of_any?(group_names)
    group_names.inject(false) { |is_member, name| is_member || self.member_of?(name) }
  end
  
  def member_of_all?(group_names)
    group_names.inject(true) { |is_member, name| is_member && self.member_of?(name) }
  end
  
  def read_only?
    ro = ["Read Only Routing User","Read Only Routing Recording User"]
    ro.include?(self.user_groups.first.name)
  end

  def self.report_ids_in_use(app_id)
    User.select(:admin_report_id).where(:app_id => app_id).map{ |u| u.admin_report_id }.compact
  end

  def current_report(app_id)
    if self.app_id == app_id
      current_company = self.company
      ar = self.admin_report
    else
      current_company = Company.find(app_id)
      ar = current_company.default_admin_report
    end

    if current_company.display_reports && ar
      ar.has_blank_default? ? "report_blank_default" : ar
    else
      "report_none"
    end
  end

  
  protected
  # before_save
  def encrypt_password
    return if password.blank?
    
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def delete_group_associations
    UserGroupsUsers.delete_all ["user_id = ?", self.id]
  end
  
  # Password is required if crypted_password is blank or if the "password" virtual attribute is not blank
  def password_required?
    crypted_password.blank? || !password.blank?
  end
end
