module CacheService
  class EntitiesMap
    include Enumerable

    def initialize(aggregator, references)
      @aggregator = aggregator
      @entities = wrap_entities(references)
      load_entities!
    end

    def each
      @entities.each do |entity|
        yield entity
      end
    end

    protected

    def wrap_entities(references)
      references.map do |reference|
        uid, key = reference.uid, reference.key
        Entity.new(uid, key, reference)
      end
    end

    def load_entities!
      @entities.each do |entity|
        if cache_response = entity.reference.cache_response
          deserialize_entity_from_cache(cache_response, entity)
        else
          entity.from_cache = false
        end
      end

      uniq_ids = uncached_entities.map { |entity| entity.uid }
      resolved_entities = @aggregator.configuration.resolve.call(uniq_ids)

      resolved_entities.each do |resolved_entity|
        uniq_id = @aggregator.configuration.uniq_id.call(resolved_entity)
        entity = uncached_entities.detect { |entity| entity.uid == uniq_id }
        entity.value = resolved_entity
      end

      store_entities(uncached_entities) if uncached_entities.any?

      true
    end

    def deserialize_entity_from_cache(cache_response, entity)
      value = @aggregator.configuration.deserialize_object.call(cache_response)
      entity.deserialization_error = false
      entity.value, entity.from_cache = value, true
    rescue
      entity.deserialization_error = true
      entity.from_cache = false
    end

    def uncached_entities
      @uncached_entities ||= @entities.select do |entity|
        entity.from_cache == false
      end
    end

    def store_entities(entities)
      keys_and_values = entities.map do |entity|
        [ entity.key,
          @aggregator.configuration.serialize_object.call(entity.value) ]
      end
      redis = @aggregator.redis.mset(*keys_and_values)
    end
  end
end