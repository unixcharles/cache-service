module CacheService::Services
  class Aggregator
    module Query

      protected

      def fetch_query(key)
        if index = redis.get(key)
          return load(index)
        end

        index = query.inject({}) do |hash, object|
          hash[uniq_id(object)] = object_key(object)
          hash
        end

        redis.set(key, dump(index))
        index
      end

    end
  end
end