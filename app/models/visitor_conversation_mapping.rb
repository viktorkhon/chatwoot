class VisitorConversationMapping
  include Redis::RedisKeys
  
  # TTL for visitor mappings (30 days)
  TTL = 30.days.to_i
  
  def self.set_conversation_for_visitor(visitor_id, website_token, conversation_token)
    return unless visitor_id.present? && website_token.present? && conversation_token.present?
    
    key = format(VISITOR_CONVERSATION_MAPPING, visitor_id: visitor_id, website_token: website_token)
    
    begin
      Rails.logger.info "[VisitorMapping] Setting conversation #{conversation_token} for visitor #{visitor_id}"
      
      $alfred.with do |conn|
        conn.setex(key, TTL, conversation_token)
      end
      
      true
    rescue => e
      Rails.logger.error "[VisitorMapping] Error setting conversation mapping: #{e.message}"
      false
    end
  end
  
  def self.get_conversation_for_visitor(visitor_id, website_token)
    return nil unless visitor_id.present? && website_token.present?
    
    key = format(VISITOR_CONVERSATION_MAPPING, visitor_id: visitor_id, website_token: website_token)
    
    begin
      conversation_token = nil
      
      $alfred.with do |conn|
        conversation_token = conn.get(key)
      end
      
      if conversation_token.present?
        Rails.logger.info "[VisitorMapping] Found conversation #{conversation_token} for visitor #{visitor_id}"
        return conversation_token
      else
        Rails.logger.debug "[VisitorMapping] No conversation found for visitor #{visitor_id}"
        return nil
      end
      
    rescue => e
      Rails.logger.error "[VisitorMapping] Error getting conversation mapping: #{e.message}"
      nil
    end
  end
  
  def self.set_contact_for_visitor(visitor_id, website_token, contact_source_id)
    return unless visitor_id.present? && website_token.present? && contact_source_id.present?
    
    key = format(VISITOR_CONTACT_MAPPING, visitor_id: visitor_id, website_token: website_token)
    
    begin
      Rails.logger.info "[VisitorMapping] Setting contact #{contact_source_id} for visitor #{visitor_id}"
      
      $alfred.with do |conn|
        conn.setex(key, TTL, contact_source_id)
      end
      
      true
    rescue => e
      Rails.logger.error "[VisitorMapping] Error setting contact mapping: #{e.message}"
      false
    end
  end
  
  def self.get_contact_for_visitor(visitor_id, website_token)
    return nil unless visitor_id.present? && website_token.present?
    
    key = format(VISITOR_CONTACT_MAPPING, visitor_id: visitor_id, website_token: website_token)
    
    begin
      contact_source_id = nil
      
      $alfred.with do |conn|
        contact_source_id = conn.get(key)
      end
      
      if contact_source_id.present?
        Rails.logger.info "[VisitorMapping] Found contact #{contact_source_id} for visitor #{visitor_id}"
        return contact_source_id
      else
        Rails.logger.debug "[VisitorMapping] No contact found for visitor #{visitor_id}"
        return nil
      end
      
    rescue => e
      Rails.logger.error "[VisitorMapping] Error getting contact mapping: #{e.message}"
      nil
    end
  end
  
  def self.set_page_info_for_visitor(visitor_id, website_token, page_info)
    return unless visitor_id.present? && website_token.present? && page_info.present?
    
    key = format(VISITOR_PAGE_INFO, visitor_id: visitor_id, website_token: website_token)
    
    begin
      Rails.logger.info "[VisitorMapping] Setting page info for visitor #{visitor_id}: #{page_info[:page_url]}"
      
      $alfred.with do |conn|
        conn.setex(key, TTL, page_info.to_json)
      end
      
      true
    rescue => e
      Rails.logger.error "[VisitorMapping] Error setting page info: #{e.message}"
      false
    end
  end
  
  def self.get_page_info_for_visitor(visitor_id, website_token)
    return nil unless visitor_id.present? && website_token.present?
    
    key = format(VISITOR_PAGE_INFO, visitor_id: visitor_id, website_token: website_token)
    
    begin
      page_info_json = nil
      
      $alfred.with do |conn|
        page_info_json = conn.get(key)
      end
      
      if page_info_json.present?
        page_info = JSON.parse(page_info_json, symbolize_names: true)
        Rails.logger.info "[VisitorMapping] Found page info for visitor #{visitor_id}: #{page_info[:page_url]}"
        return page_info
      else
        Rails.logger.debug "[VisitorMapping] No page info found for visitor #{visitor_id}"
        return nil
      end
      
    rescue => e
      Rails.logger.error "[VisitorMapping] Error getting page info: #{e.message}"
      nil
    end
  end
  
  def self.clear_visitor_data(visitor_id, website_token)
    return unless visitor_id.present? && website_token.present?
    
    conversation_key = format(VISITOR_CONVERSATION_MAPPING, visitor_id: visitor_id, website_token: website_token)
    contact_key = format(VISITOR_CONTACT_MAPPING, visitor_id: visitor_id, website_token: website_token)
    page_key = format(VISITOR_PAGE_INFO, visitor_id: visitor_id, website_token: website_token)
    
    begin
      Rails.logger.info "[VisitorMapping] Clearing all data for visitor #{visitor_id}"
      
      $alfred.with do |conn|
        conn.del(conversation_key, contact_key, page_key)
      end
      
      true
    rescue => e
      Rails.logger.error "[VisitorMapping] Error clearing visitor data: #{e.message}"
      false
    end
  end
end 