module CacheService
  class Response
    attr_reader :result, :objects_missed_count, :objects_retrived_count

    def initialize(result, from_reference_cache, objects_missed_count, objects_retrived_count)
      @result = result
      @from_reference_cache = from_reference_cache
      @objects_missed_count = objects_missed_count
      @objects_retrived_count = objects_retrived_count
    end

    def cached_query?
      !!@from_reference_cache
    end

    def objects_hit_ratio
      return 1.0 if result.size == 0
      (objects_retrived_count.to_f / result.size.to_f)
    end

    def objects_miss_ratio
      return 0.0 if result.size == 0
      (objects_missed_count.to_f / result.size.to_f)
    end
  end
end