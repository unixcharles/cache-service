module CacheService
  class Configuration

    def initialize
      @configuration = {}
    end

    def initialize_copy(*arguments)
      @configuration = @configuration.dup
      super
    end

    protected
    def method_missing(method_name, *arguments, &block)
      if method_name.to_s =~ /=\z/
        return assign_value(method_name, arguments)
      end

      if block_given?
        return @configuration[method_name] = block
      end

      if arguments.any?
        @configuration[method_name] ||= []
        return @configuration[method_name] << arguments
      end

      if arguments.empty?
        return @configuration[method_name]
      end

      super
    end

    def assign_value(method_name, arguments)
      key = method_name.to_s.gsub(/=\z/, '')
      @configuration[key.to_sym] = arguments.first
    end
  end
end