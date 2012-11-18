A cache service tool


# Initializer, global configuration.
CacheService.configure do |config|
  config.redis = $redis

  config.store do |object|
    Marshal.dump(object)
  end

  config.load do |string|
    Marshal.load(string)
  end

  config.uniq_id do |object|
    object.id
  end
end

class PostsController < ApplicationController
  include CacheService

  # Class level configuration
  cache_service do |config|
    config.prefix = 'posts'
    config.cache = $redis_posts
    config.object_key do |post|
      "#{post.id}:#{post.updated_at.to_i}"
    end
  end

  # GET /posts?page=1
  def index
    # Redis - GET 'posts:collection/page:1'
    @posts = cache_collection(:page => params[:page]) do |cache|
      # SELECT id, updated_at FROM `posts` LIMIT 10 OFFSET 0
      # SET 'posts:collection/page:1', ["post:1:1330439911", "post:2:1330425099", ... ,"post:10:1328521127"]
      # Redis - SADD 'subscription:posts:collections', ['posts:collection/page:1']
      cache.index do
        post = Post.select(:id, :updated_at).page(params[:page]).all
      end

      # Redis - Pipelined
      #   GET "post:1:1330439911"
      #   GET "post:2:1330425099"
      #   ...

      # SELECT `posts`.* FROM `posts`  WHERE `users`.`id` IN (3, 4)"
      # Redis - Pipelined
      #   SET "post:3:1343831131", "..."
      #   SET "post:4:1343827523", "..."
      cache.missing do |ids|
        Post.where(:id => ids).include(:comments).all
      end
    end
  end

  # GET /posts/1
  def show
    # Redis - GET 'posts:object/id:1'
    @post = cache_object(:id => params[:id]) do |cache|
      # SELECT id, updated_at FROM `posts` LIMIT 10 OFFSET 0
      # SET 'posts:object/id:1', "post:1:1330439911"
      cache.index do
        Post.select(:id, :updated_at).where(:id => params[:id]).first
      end

      # SELECT `posts`.* FROM `posts`  WHERE `posts`.`id` = 1 LIMIT 1"
      # SET "post:1:1343831131", "..."
      cache.find do |id|
        Post.where(:id => id).include(:comments).first
      end
    end
  end

  # POST /posts
  def create
    @post = Post.create(params[:post])

    # Redis - Pipelined
    #   SET "post:2:1343831131", "..."
    #   SET 'posts:object/id:2', "post:2:1330449921"
    # Redis - GET 'subscription:posts:collections'
    # Redis - Pipelined
    #   DEL 'posts:collection/page:1'
    #   DEL 'posts:collection/page:2'
    cache_insert(@post, :id => post.id)
  end

  # PUT /posts/1
  def update
    @post.update_attributes!(params[:post])

    # Redis - Pipelined
    #   SET "post:1:1343831131", "..."
    #   SET 'posts:object/id:1', "post:1:1330449921"
    cache_update(@post, :id => post.id)
  end

  # DELETE /posts/1
  def destroy
    @post.destroy

    # Redis - Pipelined
    #   DEL 'posts:object/id:1'
    # Redis - GET 'subscription:posts:collections'
    # Redis - Pipelined
    #   DEL 'subscription:posts:collections'
    #   DEL 'posts:collection/page:1'
    #   DEL 'posts:collection/page:2'
    cache_expire(:id => @post.id)
  end
end