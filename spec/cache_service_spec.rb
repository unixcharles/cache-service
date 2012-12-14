require 'spec_helper'
require 'support/service_helper'

describe CacheService do
  let(:posts_controller) { PostsController.new }

  it 'return a result from cold cache' do
    clear_cache!

    response = posts_controller.index
    expect( response ).to be_a(CacheService::Response)
    expect( response.result ).to eql( PostsController::COLLECTION_QUERY )
    expect( response.cached_query? ).to be_false
    expect( response.objects_missed_count ).to eql(3)
    expect( response.objects_hit_ratio ).to eql(0.0)
    expect( response.objects_miss_ratio ).to eql(1.0)
  end

  it 'return a result from warm cache' do
    clear_cache! && posts_controller.index

    response = posts_controller.index
    expect( response ).to be_a(CacheService::Response)
    expect( response.result ).to eql( PostsController::COLLECTION_QUERY )
    expect( response.cached_query? ).to be_true
    expect( response.objects_retrived_count ).to eql(3)
    expect( response.objects_hit_ratio ).to eql(1.0)
    expect( response.objects_miss_ratio ).to eql(0.0)
  end

  it 'return a result from warm query cache and cold objects cache' do
    clear_cache! && posts_controller.index && clear_cache_objects!

    response = posts_controller.index
    expect( response ).to be_a(CacheService::Response)
    expect( response.result ).to eql( PostsController::COLLECTION_QUERY )
    expect( response.cached_query? ).to be_true
    expect( response.objects_missed_count ).to eql(3)
    expect( response.objects_hit_ratio ).to eql(0.0)
    expect( response.objects_miss_ratio ).to eql(1.0)
  end

  it 'return a result from cold query cache and warm objects cache' do
    clear_cache! && posts_controller.index && clear_cache_collection!

    response = posts_controller.index
    expect( response ).to be_a(CacheService::Response)
    expect( response.result ).to eql( PostsController::COLLECTION_QUERY )
    expect( response.cached_query? ).to be_false
    expect( response.objects_retrived_count ).to eql(3)
    expect( response.objects_hit_ratio ).to eql(1.0)
    expect( response.objects_miss_ratio ).to eql(0.0)
  end

  it 'return a result from cold query cache and partial objects cache' do
    clear_cache! && posts_controller.index && clear_cache_objects!(0..1)

    response = posts_controller.index
    expect( response ).to be_a(CacheService::Response)
    expect( response.result ).to eql( PostsController::COLLECTION_QUERY )
    expect( response.cached_query? ).to be_true
    expect( response.objects_retrived_count ).to eql(1)
    expect( response.objects_hit_ratio ).to eql(1.0/3)
    expect( response.objects_miss_ratio ).to eql(2.0/3)
  end

  it 'return a empty query from cold cache' do
    clear_cache!

    response = posts_controller.index(1, 2)
    expect( response ).to be_a(CacheService::Response)
    expect( response.result ).to be_empty
    expect( response.cached_query? ).to be_false
    expect( response.objects_retrived_count ).to eql(0)
    expect( response.objects_missed_count ).to eql(0)
    expect( response.objects_hit_ratio ).to eql(1.0)
    expect( response.objects_miss_ratio ).to eql(0.0)
  end

  it 'return a empty query from warm cache' do
    clear_cache! && posts_controller.index(1, 2)

    response = posts_controller.index(1, 2)
    expect( response ).to be_a(CacheService::Response)
    expect( response.result ).to be_empty
    expect( response.cached_query? ).to be_true
    expect( response.objects_retrived_count ).to eql(0)
    expect( response.objects_missed_count ).to eql(0)
    expect( response.objects_hit_ratio ).to eql(1.0)
    expect( response.objects_miss_ratio ).to eql(0.0)
  end

  it 'subscribe the object to the collection' do
    clear_cache! && posts_controller.index
    collection_key = "cache-service-test-posts/collection/published/blog:1"

    subscriptions_keys = $redis.keys('cache-service-test-posts/object-subscriptions/*')
    expect( subscriptions_keys.size ).to eql(3)

    subscriptions_keys.each do |key|
      collection_keys = $redis.smembers(key)
      expect( collection_keys ).to include(collection_key)
    end
  end

  it 'delete expire object and referenced collection' do
    clear_cache! && posts_controller.index
    collection_key = "cache-service-test-posts/collection/published/blog:1"

    deleted_keys = posts_controller.update
    subscriptions_keys = $redis.keys('cache-service-test-posts/object-subscriptions/*')
    expect( subscriptions_keys.size ).to eql(2)

    subscriptions_keys = $redis.keys('cache-service-test-posts/object/*')
    expect( subscriptions_keys.size ).to eql(2)

    expect( deleted_keys ).to eql(3)
  end

end
