class UserSession < Authlogic::Session::Base   
  verify_password_method(:authenticated?) 
  logout_on_timeout true
  generalize_credentials_error_messages true
  allow_http_basic_auth false
  
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
  
  # Needed to add this in to have Authlogic work with Rails 3
  def to_key
    new_record? ? nil : [ self.send(self.class.primary_key) ]
  end
end
