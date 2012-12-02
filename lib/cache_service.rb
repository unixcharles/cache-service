require 'cache_service/configuration'

require 'cache_service/proxy/class_methods'
require 'cache_service/proxy/instance_methods'

require 'cache_service/formatted_key'

require 'cache_service/aggregator'
require 'cache_service/entity'
require 'cache_service/entities_map'
require 'cache_service/entities_repository'
require 'cache_service/reference'
require 'cache_service/references_map'
require 'cache_service/references_repository'
require 'cache_service/references_subscriber'
require 'cache_service/response'

require 'cache_service/expiration'

module CacheService
  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.included(klass)
    klass.send :extend, Proxy::ClassMethods
    klass.send :include, Proxy::InstanceMethods
  end
end