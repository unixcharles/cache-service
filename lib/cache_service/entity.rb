module CacheService
  class Entity
    attr_accessor :uid, :key, :reference, :value, :from_cache, :deserialization_error

    def initialize(uid, key, reference)
      @uid, @key,  @reference = uid, key, reference
    end

  end
end