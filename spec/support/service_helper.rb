require 'cache_service'
require 'redis'

$redis = Redis.new

def clear_cache!
  $redis.keys('cache-service-test-*').each { |key| $redis.del(key) }
end

def clear_cache_objects!(range = nil)
  keys = $redis.keys('cache-service-test-posts/object/*')
  if range
    keys[range]
  else
    keys
  end.each { |key| $redis.del(key) }
end

def clear_cache_collection!
  $redis.keys('cache-service-test-posts/collection/*').each { |key| $redis.del(key) }
end

def load_cache!(*arguments)
  arguments.each do |hash|
    hash.each do |k, v|
      $redis.set(k, Marshal.dump(v))
    end
  end
end

CacheService.configure do |config|
  config.redis = $redis
  config.serialize_references   { |object| Marshal.dump(object) }
  config.deserialize_references { |string| Marshal.load(string) }
  config.serialize_object       { |object| Marshal.dump(object) }
  config.deserialize_object     { |string| Marshal.load(string) }
  config.uniq_id                { |object| object[:id] }
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
    config.prefix = 'cache-service-test-posts'
    config.object_key { |post| "#{post[:id]}:#{post[:updated_at].to_i}" }
  end


  def index(blog_id = 1, page = 1)
    cache_aggregator(:blog => blog_id) do |cache|
      cache.params(:page => page)
      cache.query do
        page =  page - 1
        COLLECTION_QUERY.map do |item|
          item.select {|key| [:id, :updated_at].include? key }
        end[(page*3)..(page*3)+3].to_a
      end

      cache.resolve do |ids|
        COLLECTION_QUERY.select { |item| ids.include?(item[:id]) }
      end
    end
  end

  def update(post_id = 1, blog_id = 1)
    cache_expiration COLLECTION_QUERY.select {|object| object[:id] == post_id }
  end
end
