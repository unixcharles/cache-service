module CacheService
  class EntitiesRepository
    def initialize(aggregator)
      @aggregator = aggregator
      @redis = aggregator.redis
    end

    # Public: Get the reference from cache or query
    #
    # Returns - Instance of ReferenceMap
    def call(references_map)
      entities_keys = references_map.map { |reference| reference.key }
      cache_reponses = if entities_keys.any?
        @redis.mget(*entities_keys)
      else
        []
      end

      cache_reponses.each_with_index do |cache_response, index|
        references_map.references[index].cache_response = cache_response
      end

      EntitiesMap.new(@aggregator, references_map)
    end

  end
end