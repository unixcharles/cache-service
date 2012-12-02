module CacheService
  class ReferencesMap
    include Enumerable

    attr_reader :references

    def initialize(aggregator, reference_objects)
      @aggregator = aggregator
      @references = wrap_reference_objects(reference_objects)
    end

    def each
      @references.each do |reference|
        yield reference
      end
    end

    protected
    def wrap_reference_objects(reference_objects)
      reference_objects.each.map do |reference_object|
        [ @aggregator.configuration.uniq_id.call(reference_object),
          object_key(reference_object),
          object_subscriptions_key(reference_object),
          reference_object ]
      end.map { |args| Reference.new *args }
    end

    def object_key(reference_object)
      key = @aggregator.configuration.object_key.call reference_object
      prefix = @aggregator.configuration.prefix
      "#{prefix}/object/#{key}"
    end

    def object_subscriptions_key(reference_object)
      key = @aggregator.configuration.object_key.call reference_object
      prefix = @aggregator.configuration.prefix
      "#{prefix}/object-subscriptions/#{key}"
    end

  end
end