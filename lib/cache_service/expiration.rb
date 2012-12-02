module CacheService
  class Expiration
    attr_reader :configuration
    attr_accessor :collection_identifier_key
    attr_writer :from_reference_cache

    def initialize(configuration, objects, configuration_block)
      @configuration = configuration
      @objects = objects
      configuration_block.call(@configuration) if configuration_block
    end

    def call
      references_map = ReferencesMap.new(self, @objects)
      keys = collection_keys(references_map) + object_keys(references_map)
      redis.del(keys.uniq)
    end

    def redis
      @configuration.redis
    end

    def object_keys(references_map)
      references_map.map do |reference|
        [reference.key, reference.subscriptions_key]
      end.flatten
    end

    def collection_keys(references_map)
      responses = []

      redis.multi do
        references_map.each do |reference|
          responses << redis.smembers(reference.subscriptions_key)
        end
      end
      keys = responses.map {|response| response.value }.flatten
    end
  end
end