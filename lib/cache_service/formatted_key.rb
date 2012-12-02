module CacheService
  module FormattedKey
    private
    def formatted_key(arguments)
      arguments.to_a.map do |argument|
        case argument
        when Hash then argument.to_a.join(":")
        when Array then formatted_key(argument)
        else
          argument.to_s
        end
      end.join('/')
    end
  end
end