module CacheService
  class ReferencesSubscriber
    def initialize(aggregator)
      @aggregator = aggregator
      @collection_identifier_key = aggregator.collection_identifier_key
    end

    def call(references_map)
      redis.multi do
        references_map.each do |reference|
          redis.sadd reference.subscriptions_key, @collection_identifier_key
        end
      end
    end

    def redis
      @aggregator.redis
    end
  end
end