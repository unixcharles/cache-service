%w(aggregator collection entities).each do |service|
  require "cache_service/services/#{service}"
end