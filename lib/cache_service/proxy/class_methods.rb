module CacheService
  module Proxy
    module ClassMethods
      def cache_service_configuration
        @cache_service_configuration
      end

      def cache_service(&block)
        @cache_service_configuration = CacheService.configuration.dup
        block.call(@cache_service_configuration)
      end
    end
  end
end