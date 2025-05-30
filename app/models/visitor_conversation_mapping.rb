# frozen_string_literal: true

class VisitorConversationMapping
  # TTL for visitor mappings (30 days)
  TTL = 30.days.to_i
  
  class << self
    def set_conversation_for_visitor(visitor_id, website_token, conversation_token)
      return false unless valid_params?(visitor_id, website_token, conversation_token)
      
      key = format('VISITOR_CONVERSATION::%<visitor_id>s::%<website_token>s', visitor_id: visitor_id, website_token: website_token)
      redis_operation { |conn| conn.setex(key, TTL, conversation_token) }
    end
    
    def get_conversation_for_visitor(visitor_id, website_token)
      return nil unless valid_params?(visitor_id, website_token)
      
      key = format('VISITOR_CONVERSATION::%<visitor_id>s::%<website_token>s', visitor_id: visitor_id, website_token: website_token)
      redis_operation { |conn| conn.get(key) }
    end
    
    def set_contact_for_visitor(visitor_id, website_token, contact_source_id)
      return false unless valid_params?(visitor_id, website_token, contact_source_id)
      
      key = format('VISITOR_CONTACT::%<visitor_id>s::%<website_token>s', visitor_id: visitor_id, website_token: website_token)
      redis_operation { |conn| conn.setex(key, TTL, contact_source_id) }
    end
    
    def get_contact_for_visitor(visitor_id, website_token)
      return nil unless valid_params?(visitor_id, website_token)
      
      key = format('VISITOR_CONTACT::%<visitor_id>s::%<website_token>s', visitor_id: visitor_id, website_token: website_token)
      redis_operation { |conn| conn.get(key) }
    end
    
    def set_page_info_for_visitor(visitor_id, website_token, page_info)
      return false unless valid_params?(visitor_id, website_token) && page_info.present?
      
      key = format('VISITOR_PAGE_INFO::%<visitor_id>s::%<website_token>s', visitor_id: visitor_id, website_token: website_token)
      redis_operation { |conn| conn.setex(key, TTL, page_info.to_json) }
    end
    
    def get_page_info_for_visitor(visitor_id, website_token)
      return nil unless valid_params?(visitor_id, website_token)
      
      key = format('VISITOR_PAGE_INFO::%<visitor_id>s::%<website_token>s', visitor_id: visitor_id, website_token: website_token)
      page_info_json = redis_operation { |conn| conn.get(key) }
      
      return nil unless page_info_json.present?
      
      JSON.parse(page_info_json, symbolize_names: true)
    rescue JSON::ParserError => e
      Rails.logger.error "[VisitorMapping] JSON parsing failed: #{e.message}"
      nil
    end
    
    def clear_visitor_data(visitor_id, website_token)
      return false unless valid_params?(visitor_id, website_token)
      
      keys = [
        format('VISITOR_CONVERSATION::%<visitor_id>s::%<website_token>s', visitor_id: visitor_id, website_token: website_token),
        format('VISITOR_CONTACT::%<visitor_id>s::%<website_token>s', visitor_id: visitor_id, website_token: website_token),
        format('VISITOR_PAGE_INFO::%<visitor_id>s::%<website_token>s', visitor_id: visitor_id, website_token: website_token)
      ]
      
      redis_operation { |conn| conn.del(*keys) }
    end

    private

    def valid_params?(*params)
      params.all?(&:present?)
    end

    def redis_operation
      return nil unless block_given?
      
      result = $alfred.with do |conn|
        yield(conn)
      end
      result
    rescue Redis::BaseError => e
      Rails.logger.error "[VisitorMapping] Redis operation failed: #{e.message}"
      nil
    rescue StandardError => e
      Rails.logger.error "[VisitorMapping] Unexpected error: #{e.message}"
      nil
    end
  end
end 
