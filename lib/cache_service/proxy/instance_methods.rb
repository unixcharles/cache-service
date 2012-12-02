module CacheService
  module Proxy
    module InstanceMethods
      def cache_aggregator(*arguments, &block)
        aggregator = Aggregator.new(cache_service_configuration.dup, arguments, block)
        aggregator.call
      end

      def cache_expiration(*objects, &block)
        expiration = Expiration.new(cache_service_configuration.dup, objects.flatten, block)
        expiration.call
      end

      protected
      def cache_service_configuration
        self.class.cache_service_configuration
      end
    end
  end
end