class Racc::App
  module Config
    def self.alpha
      {:adapter => 'tinytds', 
       :host =>'sdwsql01', 
       :database => 'racc_v2b_alpha', 
       :user => 'racc_v2b_alpha', 
       :password => 'racc_v2b_alpha8245'}
    end
  end
end
