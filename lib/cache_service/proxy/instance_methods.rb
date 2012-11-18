module CacheService
  module Proxy
    module InstanceMethods
      def cache_collection(*arguments, &block)
        @cache_collection ||= Services::Collection.new(cache_service_configuration)
        @cache_collection.call(block, *arguments)
      end

      protected
      def cache_service_configuration
        self.class.cache_service_configuration
      end
    end
  end
end