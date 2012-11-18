module CacheService::Services
  class Collection < Aggregator

    def collection_query_key(*arguments)
      build_arguments_key('collection-query', arguments)
    end

    protected
    def query
      @miss = true
      @configuration.query.call
    end

    def resolve(ids)
      @partial_miss = ids.size
      @configuration.resolve.call(ids)
    end
  end
end
