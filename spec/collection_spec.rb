require 'spec_helper'
require 'support/service_helper'
require 'cache_service'

describe 'Collection query' do
  include CacheService

  INDEX_CACHE = { 'cache-service-test-posts:collection-query/page:1' => {
                  1 => "cache-service-test-posts:object/1:1344107655",
                  2 => "cache-service-test-posts:object/2:1276902272",
                  3 => "cache-service-test-posts:object/3:1209696889" }
                }

  OBJECT_CACHE = { "cache-service-test-posts:object/1:1344107655" => { :id=>1, :updated_at=> Time.at(1344107655), :body=>"Hello world 1" },
                   "cache-service-test-posts:object/2:1276902272" => { :id=>2, :updated_at=> Time.at(1276902272), :body=>"Hello world 2" },
                   "cache-service-test-posts:object/3:1209696889" => { :id=>3, :updated_at=> Time.at(1209696889), :body=>"Hello world 3" }
                 }

  before :each do
    @post_controller = PostsController.new
    $redis = Redis.new
    clear_cache!
  end

  it 'perform query when the cache is cold' do
    collection = @post_controller.index
    expect( PostsController::COLLECTION_QUERY ).to eql(collection)

    expect( query_from_cache? ).to be_false
    expect( objects_from_cache? ).to be_false
  end

  it 'retrive data from cache when the cache is warm' do
    load_cache!(INDEX_CACHE, OBJECT_CACHE)

    collection = @post_controller.index
    expect( PostsController::COLLECTION_QUERY ).to eql(collection)

    expect( query_from_cache? ).to be_true
    expect( objects_from_cache? ).to be_true
  end

  it 'perform the query and retrive objects from cache' do
    load_cache!(OBJECT_CACHE)

    collection = @post_controller.index

    expect( PostsController::COLLECTION_QUERY ).to eql(collection)

    expect( query_from_cache? ).to be_false
    expect( objects_from_cache? ).to be_true
  end

  it 'retrive the query from cache and perform query for objects' do
    load_cache!(INDEX_CACHE)

    collection = @post_controller.index

    expect( PostsController::COLLECTION_QUERY ).to eql(collection)

    expect( query_from_cache? ).to be_true
    expect( objects_from_cache? ).to be_false
  end

  it 'retrive the query from cache and resolve missing objects' do
    partial_object_cache = OBJECT_CACHE
    partial_object_cache.delete(OBJECT_CACHE.keys.first)
    load_cache!(INDEX_CACHE, partial_object_cache)

    collection = @post_controller.index

    expect( PostsController::COLLECTION_QUERY ).to eql(collection)

    expect( query_from_cache? ).to be_true
    expect( objects_from_cache? ).to be_false
  end

  it 'perform the query query and resolve missing objects' do
    partial_object_cache = OBJECT_CACHE
    missing_object = partial_object_cache.delete(OBJECT_CACHE.keys.first)
    load_cache!(partial_object_cache)

    collection = @post_controller.index

    expect( PostsController::COLLECTION_QUERY ).to eql(collection)

    expect( query_from_cache? ).to be_false
    expect( objects_from_cache? ).to be_false
  end

  it 'retrive empty query' do
    collection = @post_controller.index(2)
    expect( collection ).to be_empty
  end

  it 'subscribe every object to the query' do
    collection = @post_controller.index

    object_keys = INDEX_CACHE['cache-service-test-posts:collection-query/page:1'].values

    object_keys.each do |object_key|
      $redis.smembers('cache-service-test-posts:subscription-object-collections')
    end
  end

  def query_from_cache?
    Thread.current[:query_from_cache]
  end

  def objects_from_cache?
    Thread.current[:objects_from_cache]
  end
end
