require 'cache_service/configuration'

require 'cache_service/proxy/class_methods'
require 'cache_service/proxy/instance_methods'

require 'cache_service/services'

module CacheService
  def self.configure(&block)
    config = configuration
    block.call(config)
    @configuration = config
  end

  def self.configuration
    @configuration || @configuration = Configuration.new
  end

  def self.included(klass)
    klass.send :extend, Proxy::ClassMethods
    klass.send :include, Proxy::InstanceMethods
  end
end