class Racc::App
  module Config
    def self.alpha
      {:adapter => 'tinytds', 
       :host =>'sdwsql01', 
       :database => 'racc_v2b_alpha', 
       :username => 'racc_v2b_alpha', 
       :password => 'racc_v2b_alpha8245'}
    end

    def self.local
      {:adapter => 'postgresql', 
       :host =>'localhost', 
       :database => 'racc_dev', 
       :username => 'root', 
       :password => ''}
    end
  end
end
