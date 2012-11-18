require 'cache_service/services/base'
require 'cache_service/services/aggregator/query'
require 'cache_service/services/aggregator/resolve'
require 'cache_service/services/aggregator/subscribe'

module CacheService
  module Services
    class Aggregator
      include Base
      include Query
      include Resolve
      include Subscribe

      protected

      def perform!(*arguments)
        query_key = collection_query_key(*arguments)
        object_keys = fetch_query(query_key)
        collection = if object_keys.empty?
          []
        else
          resolve_collection(object_keys)
        end

        if @miss
          subscribe(query_key, collection)
          @miss = nil
        end

        collection
      end
    end
  end
end
