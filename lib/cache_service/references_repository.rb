module CacheService
  class ReferencesRepository
    include FormattedKey

    def initialize(aggregator)
      @aggregator = aggregator
      @collection_identifier = aggregator.collection_identifier_key = collection_identifier_key
      @collection_params = formatted_key(aggregator.configuration.params)
      @redis = aggregator.redis
    end

    # Public: Get the reference from cache or query
    #
    # Returns - Instance of ReferenceMap
    def call
      reference_objects = if cache_reponse = @redis.hget(@collection_identifier, @collection_params)
        from_cache(cache_reponse)
      else
        from_query
      end

      ReferencesMap.new(@aggregator, reference_objects)
    end

    protected
    def from_cache(cache_reponse)
      @aggregator.from_reference_cache = true
      @aggregator.configuration.deserialize_references.call(cache_reponse)
    end

    def from_query
      @aggregator.from_reference_cache = false
      reference_objects = @aggregator.configuration.query.call
      store(reference_objects)
      reference_objects
    end

    def store(reference_objects)
      cache_response = @aggregator.configuration.serialize_references.call(reference_objects)
      @redis.hset(@collection_identifier, @collection_params, cache_response)
    end

    def collection_identifier_key
      key = formatted_key(@aggregator.configuration.collection_identifier)
      prefix = @aggregator.configuration.prefix
      "#{prefix}/collection/#{key}"
    end
  end
end