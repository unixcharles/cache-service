module CacheService
  class Aggregator
    attr_reader :configuration
    attr_accessor :collection_identifier_key
    attr_writer :from_reference_cache

    def initialize(configuration, arguments, configuration_block)
      @configuration = configuration
      @configuration.collection_identifier = arguments
      configuration_block.call(@configuration) if configuration_block
    end

    def call
      @references_map = ReferencesRepository.new(self).call
      ReferencesSubscriber.new(self).call(@references_map)
      @entities_map = EntitiesRepository.new(self).call(@references_map)

      objects = @entities_map.map {|entity| entity.value }
      objects_missed_count = @entities_map.count { |entity| entity.from_cache == false }
      objects_retrived_count = @entities_map.count { |entity| entity.from_cache == true }

      Response.new(objects, @from_reference_cache, objects_missed_count, objects_retrived_count)
    end

    def redis
      @configuration.redis
    end
  end
end