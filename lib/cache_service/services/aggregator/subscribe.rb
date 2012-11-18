module CacheService::Services
  class Aggregator
    module Subscribe

      protected

      def subscription_keys(objects)
        objects.map do |object|
          "#{object_key(object)}/subscriptions"
        end
      end

      def subscribe(query_key, objects)
        subscription_keys(objects).each do |subscription_key|
          pipelined(objects.size) do
            redis.sadd(subscription_key, query_key)
          end
        end
      end

    end
  end
end