module CacheService::Services
  class Aggregator
    module Resolve

      protected

      def resolve_collection(index)
        partial_collection = get_partial_collection(index)
        collection = if partial_collection.values.any? {|value| value.nil? }
          complete_collection(partial_collection)
        else
          partial_collection
        end

        collection.values
      end

      def get_partial_collection(index)
        values = fetch_values_from_cache(index)
        partial_collection = empty_collection(index)
        values.each do |value|
          partial_collection[uniq_id(value)] = value
        end

        partial_collection
      end

      def fetch_values_from_cache(index)
        raw_values = redis.mget index.values
        raw_values.compact.map {|value| load(value) }
      end

      def empty_collection(index)
        index.keys.inject({}) do |hash, key|
          hash[key]=nil
          hash
        end
      end

      def complete_collection(partial_collection)
        missing_object_ids = collect_missing_ids(partial_collection)
        missing_objects = resolve_missing_objects(missing_object_ids)
        cache_missing_objects(missing_objects)
        resolve_partial_collection(partial_collection, missing_objects)
      end

      def collect_missing_ids(partial_collection)
        partial_collection.select do |k,v|
          v.nil?
        end.keys
      end

      def resolve_missing_objects(ids)
        missing_objects = resolve(ids)
        missing_objects.inject({}) do |hash, object|
          hash[uniq_id(object)] = object
          hash
        end
      end

      def cache_missing_objects(objects)
        pipelined(objects.size) do
          objects.each do |key, object|
            redis.set(object_key(object), dump(object))
          end
        end
      end

      def resolve_partial_collection(partial_collection, missing_objects)
        complete_collection = partial_collection.dup
        missing_objects.each do |key, value|
          complete_collection[key] = value.nil? ? missing_objects[key] : value
          complete_collection
        end

        complete_collection
      end

    end
  end
end