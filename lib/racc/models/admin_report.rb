class AdminReport < ActiveRecord::Base
  self.table_name = "web_admin_reports"

  has_many :users

  validates_presence_of :app_id, :name, :username, :url, :unless => :creating_default
  validates_presence_of :password, :password_confirmation, :if => :pwd_needs_validation?
  validates_confirmation_of :password
  validates_uniqueness_of :name, :scope => :app_id

  before_save :determine_password

  DEFAULT_NAME = "Default"

  attr_accessor :password_confirmation

  def is_default?
    self.name == DEFAULT_NAME
  end

  def has_blank_default?
    is_default? && (username.blank? || password.blank? || url.blank?)
  end

  private

  def creating_default
    is_default? && self.new_record?
  end

  def determine_password
    if !self.new_record? && self.password.blank?
      self.password = self.password_was
    end
  end

  def pwd_needs_validation?
    creating_a_non_default_report = self.new_record? && !is_default?
    updating_a_blank_default_report = self.persisted? && is_default? && self.password_was.blank?

    (creating_a_non_default_report || updating_a_blank_default_report) ? true : false
  end
end
