module CacheService
  module Services
    module Base
      def initialize(configuration)
        @configuration = configuration.dup
      end

      def call(block, *arguments)
        block.call(@configuration)
        perform!(*arguments)
      end

      protected
      def build_arguments_key(name, arguments)
        arguments.inject("#{prefix}:#{name}") do |key, argument|
          key += "/#{convert_argument_to_key(argument)}"
          key
        end
      end

      def convert_argument_to_key(argument)
        return convert_hash_argument_to_key(argument) if argument.is_a?(Hash)
        argument.to_s
      end

      def convert_hash_argument_to_key(argument)
        argument.map { |key,value| "#{key}:#{value}" }.join('/')
      end

      def prefix
        @configuration.prefix
      end

      def uniq_id(object)
        @configuration.uniq_id.call(object)
      end

      def object_key(object)
        "#{prefix}:object/#{@configuration.object_key.call(object)}"
      end

      def load(value)
        @configuration.load.call(value) if value
      end

      def dump(value)
        @configuration.dump.call(value) if value
      end

      def redis
        @configuration.redis
      end

      def pipelined(command_count)
        threshold = @configuration.pipelined_threshold || 2
        if command_count >= threshold
          redis.pipelined do
            yield
          end
        else
          yield
        end
      end

    end
  end
end