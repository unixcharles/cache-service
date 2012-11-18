module CacheService::Services
  class CacheObject < Aggregator

    protected

    def collection_query_key(*arguments)
      build_arguments_key('object-query', arguments)
    end

    def subscription_key(arguments)
      build_arguments_key('subscription-object', arguments)
    end

    def query
      @miss = true
      result = @configuration.query.call
      [result].compact
    end

    def resolve(ids)
      @partial_miss = ids.size
      [@configuration.resolve.call(ids.first)]
    end

    def perform!(*arguments)
      (super).first
    end
  end
end
