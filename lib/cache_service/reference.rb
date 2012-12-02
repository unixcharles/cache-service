module CacheService
  class Reference
    attr_accessor :cache_response
    attr_reader :uid, :key, :subscriptions_key, :object

    def initialize(uid, key, subscriptions_key, object)
      @uid, @key, @subscriptions_key, @object = uid, key, subscriptions_key, object
    end
  end
end