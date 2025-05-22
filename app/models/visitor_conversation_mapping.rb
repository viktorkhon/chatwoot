class VisitorConversationMapping
  def self.redis
    Redis::Namespace.new('visitor_conversations', redis: Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379')))
  end

  def self.set_mapping(visitor_id, conversation_id, expires_in: 30.days)
    # Store mapping of visitor_id -> conversation_id
    redis.set(visitor_id, conversation_id)
    redis.expire(visitor_id, expires_in.to_i)
  end

  def self.get_conversation_id(visitor_id)
    redis.get(visitor_id)
  end

  def self.delete_mapping(visitor_id)
    redis.del(visitor_id)
  end
end 