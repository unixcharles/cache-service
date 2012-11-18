require 'cache_service'
require 'redis'

$redis = Redis.new

def clear_cache!
  $redis.keys('cache-service-test-*').each { |key| $redis.del(key) }
end

def load_cache!(*arguments)
  arguments.each do |hash|
    hash.each do |k, v|
      $redis.set(k, Marshal.dump(v))
    end
  end
end

class PostsController
  include CacheService

  COLLECTION_QUERY = [
    {:id => 1, :updated_at => Time.at(1344107655), :body => 'Hello world 1'},
    {:id => 2, :updated_at => Time.at(1276902272), :body => 'Hello world 2'},
    {:id => 3, :updated_at => Time.at(1209696889), :body => 'Hello world 3'}
  ]

  # Class level configuration
  cache_service do |config|
    config.redis = $redis

    config.dump { |object| Marshal.dump(object) }
    config.load { |string| Marshal.load(string) }

    config.uniq_id { |object| object[:id] }
    config.prefix = 'cache-service-test-posts'
    config.object_key { |post| "#{post[:id]}:#{post[:updated_at].to_i}" }
  end


  def index(page = 1)
    Thread.current[:query_from_cache] = true
    Thread.current[:objects_from_cache] = true

    cache_collection(:page => page) do |cache|
      cache.query do
        Thread.current[:query_from_cache] = false
        page =  page - 1
        COLLECTION_QUERY.map { |item| item.select {|key| [:id, :updated_at].include? key } }[(page*3)..(page*3)+3].to_a
      end

      cache.listen(:post_collection)
      cache.listen(:blog => 1)

      cache.resolve do |ids|
        Thread.current[:objects_from_cache] = false
        COLLECTION_QUERY.select { |item| ids.include?(item[:id]) }
      end
    end
  end

  def show(id = 1)
      $query_from_cache, $object_from_cache = true, true

    cache_object(:id => id) do |cache|
      cache.query do
        $objects_from_cache = false

        COLLECTION_QUERY.map { |item|
          item.select {|key| [:id, :updated_at].include? key }
        }.detect {|object| object[:id] == id }
      end

      cache.listen(:post_id => id)
      cache.listen(:comments, :post_id => id)

      cache.resolve do |id|
        $object_from_cache = false
        COLLECTION_QUERY.detect {|object| object[:id] == id }
      end
    end
  end
end
