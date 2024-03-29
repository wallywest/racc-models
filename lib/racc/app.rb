require "racc/models/version"

require 'rack'
require 'logger'
require 'active_record'
require 'rack/contrib'
require 'pry'

module Racc
  class App
    autoload :Base, 'racc/base'
    autoload :Endpoint, 'racc/endpoint'
    autoload :Config, 'racc/config'
    autoload :Extensions, 'racc/extensions'
    autoload :Exporters, 'racc/exporter'
    autoload :Services, 'racc/services'

    def self.new
      setup
      super
    end

    def self.setup?
      @setup ||= false
    end

    def self.setup
      setup! unless setup?
    end


    attr_accessor :app

    def initialize
      @app = Rack::Builder.app do
        use Rack::Deflater
        use Rack::PostBodyContentTypeParser

        Endpoint.subclasses.each {|e| map(e.prefix) {run(e.new)}}
      end
    end

    def call(env)
      app.call(env)
    rescue
      raise
    end
    

    private

    def self.setup!
      load_models
      load_endpoints
      setup_endpoints

      @setup = true
    end

    def self.load_models
      ActiveRecord::Base.establish_connection(Config::local)

      require "racc/models/group"
      #require "racc/models/vlabel_map"
      #require "racc/models/destination"
    end

    def self.load_endpoints
      require_relative "endpoint/test"
    end

    def self.setup_endpoints
      Base.subclasses.each(&:setup)
    end

  end
end
