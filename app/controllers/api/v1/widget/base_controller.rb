# frozen_string_literal: true

class Api::V1::Widget::BaseController < ApplicationController
  include SwitchLocale
  include WebsiteTokenHelper

  before_action :set_web_widget
  before_action :set_contact

  private

  def conversations
    return Conversation.none unless @contact_inbox.present?

    inbox_id = auth_token_params[:inbox_id] || @web_widget&.inbox&.id
    return Conversation.none if inbox_id.nil?

    if @contact_inbox.hmac_verified?
      verified_contact_inbox_ids = @contact.contact_inboxes.where(inbox_id: inbox_id, hmac_verified: true).map(&:id)
      @conversations = @contact.conversations.where(contact_inbox_id: verified_contact_inbox_ids)
    else
      @conversations = @contact_inbox.conversations.where(inbox_id: inbox_id)
    end
    
    @conversations
  rescue StandardError => e
    Rails.logger.error "[Widget] Conversations lookup failed: #{e.message}"
    Conversation.none
  end

  def conversation
    # Only perform lookup if we don't have a conversation cached
    # AND we're in a context that should trigger conversation lookup
    @conversation ||= find_conversation_for_context
  end

  def create_conversation
    Rails.logger.info "[Widget] Creating NEW conversation for visitor: #{visitor_id}"
    
    conversation_params_data = build_conversation_params_with_page_info
    new_conversation = ::Conversation.create!(conversation_params_data)
    store_conversation_in_redis(new_conversation) if should_store_in_redis?
    
    Rails.logger.info "[Widget] ✅ NEW conversation created: #{new_conversation.id}"
    new_conversation
  rescue StandardError => e
    Rails.logger.error "[Widget] Conversation creation failed: #{e.message}"
    raise
  end

  # Core conversation lookup logic - this is the key method that needs to work properly
  def find_or_build_conversation
    Rails.logger.info "[Widget] 🔍 Looking up conversation for visitor: #{visitor_id}"
    
    # Try Redis first for incognito users - this works even when @contact_inbox is nil
    conversation_from_redis = find_conversation_via_redis
    if conversation_from_redis
      Rails.logger.info "[Widget] ✅ Using Redis conversation: #{conversation_from_redis.id}"
      
      # CRITICAL: If we found a conversation via Redis but don't have @contact_inbox set,
      # we need to set it based on the conversation we found
      if @contact_inbox.nil?
        @contact_inbox = conversation_from_redis.contact_inbox
        @contact = @contact_inbox.contact
        Rails.logger.info "[Widget] ✅ Set contact_inbox from Redis conversation: #{@contact_inbox.source_id}"
      end
      
      return conversation_from_redis
    end

    Rails.logger.info "[Widget] 🔍 Redis lookup failed, trying database lookup..."
    
    # For database lookup, we need @contact_inbox to be set
    return nil unless @contact_inbox.present?
    
    # Fallback to database lookup (this now automatically stores in Redis)
    conversation_from_db = find_conversation_via_database_with_redis_storage
    if conversation_from_db
      Rails.logger.info "[Widget] ✅ Using database conversation: #{conversation_from_db.id}"
      return conversation_from_db
    end
    
    # Only log when no conversation is found - this is the critical issue
    Rails.logger.warn "[Widget] ❌ No conversation found for visitor: #{visitor_id}, contact_inbox: #{@contact_inbox&.source_id}"
    nil
  end

  def find_conversation_via_redis
    return nil unless visitor_id.present?

    Rails.logger.info "[Widget] 🔍 Checking Redis for visitor: #{visitor_id}"
    
    conversation_token = VisitorConversationMapping.get_conversation_for_visitor(visitor_id, @web_widget.website_token)
    
    if conversation_token.present?
      Rails.logger.info "[Widget] 🔍 Found Redis conversation token for visitor: #{visitor_id}"
    else
      Rails.logger.info "[Widget] 🔍 No Redis conversation token found for visitor: #{visitor_id}"
      return nil
    end
    
    # Combined validation and extraction to eliminate redundancy
    conversation = validate_and_extract_conversation_from_token(visitor_id, conversation_token)
    
    if conversation.present?
      Rails.logger.info "[Widget] ✅ Found conversation via Redis: #{conversation.id}"
      
      # CRITICAL: If we found a conversation via Redis but don't have @contact_inbox set,
      # we need to set it based on the conversation we found
      if @contact_inbox.nil?
        @contact_inbox = conversation.contact_inbox
        @contact = @contact_inbox.contact
        Rails.logger.info "[Widget] ✅ Set contact_inbox from Redis conversation: #{@contact_inbox.source_id}"
      end
      
      conversation
    else
      Rails.logger.warn "[Widget] ❌ Redis mapping validation failed - clearing stale mapping for visitor: #{visitor_id}"
      VisitorConversationMapping.clear_visitor_data(visitor_id, @web_widget.website_token)
      nil
    end
  end

  def validate_and_extract_conversation_from_token(visitor_id, conversation_token)
    return nil unless visitor_id.present? && conversation_token.present?
    
    # Ensure conversation_token is a string
    unless conversation_token.is_a?(String)
      Rails.logger.error "[Widget] ❌ Invalid conversation token type: #{conversation_token.class}, value: #{conversation_token.inspect}"
      return nil
    end
    
    begin
      Rails.logger.info "[Widget] 🔍 Starting Redis validation for visitor: #{visitor_id}"
      
      # Decode token once
      token_data = ::Widget::TokenService.new(token: conversation_token).decode_token
      Rails.logger.info "[Widget] 🔍 Token decoded successfully: #{token_data.inspect}"
      
      return nil unless token_data[:source_id].present?
      
      Rails.logger.info "[Widget] 🔍 Validating Redis token - source_id: #{token_data[:source_id]}, conversation_id: #{token_data[:conversation_id]}"
      
      # Find contact_inbox from token
      contact_inbox = @web_widget.inbox.contact_inboxes.find_by(source_id: token_data[:source_id])
      unless contact_inbox
        Rails.logger.warn "[Widget] ❌ Contact_inbox not found for source_id: #{token_data[:source_id]}"
        return nil
      end
      
      Rails.logger.info "[Widget] ✅ Found contact_inbox from token: #{contact_inbox.source_id}"
      
      # If we have a current contact_inbox, verify it matches the token
      if @contact_inbox.present? && token_data[:source_id] != @contact_inbox.source_id
        Rails.logger.warn "[Widget] ❌ Token source_id mismatch: token=#{token_data[:source_id]}, current=#{@contact_inbox.source_id}"
        return nil
      end

      Rails.logger.info "[Widget] ✅ Source_id validation passed, proceeding with conversation extraction"
      
      # Extract conversation from token data
      conversation = extract_conversation_from_token_data(contact_inbox, token_data)
      
      if conversation.present?
        Rails.logger.info "[Widget] ✅ Successfully extracted conversation: #{conversation.id}"
      else
        Rails.logger.warn "[Widget] ❌ Failed to extract conversation from valid token"
      end
      
      conversation
    rescue StandardError => e
      Rails.logger.error "[Widget] ❌ Redis validation and extraction exception: #{e.message}"
      Rails.logger.error "[Widget] ❌ Exception backtrace: #{e.backtrace.first(3).join(', ')}"
      nil
    end
  end

  def extract_conversation_from_token_data(contact_inbox, token_data)
    # Try specific conversation ID first
    if token_data[:conversation_id].present?
      Rails.logger.info "[Widget] 🔍 Looking for specific conversation #{token_data[:conversation_id]} in contact_inbox #{contact_inbox.source_id}"
      specific_conversation = contact_inbox.conversations.find_by(id: token_data[:conversation_id])
      
      if specific_conversation.present?
        Rails.logger.info "[Widget] 🔍 Conversation #{token_data[:conversation_id]} found with status: #{specific_conversation.status}"
        
        if specific_conversation.status != 'resolved'
          Rails.logger.info "[Widget] ✅ Using specific conversation: #{specific_conversation.id}"
          return specific_conversation
        else
          Rails.logger.warn "[Widget] ❌ Conversation #{token_data[:conversation_id]} is resolved, cannot use"
        end
      else
        Rails.logger.warn "[Widget] ❌ Conversation #{token_data[:conversation_id]} not found in contact_inbox #{contact_inbox.source_id}"
      end
    end

    # Fallback to last open conversation
    Rails.logger.info "[Widget] 🔍 Falling back to last open conversation for contact_inbox #{contact_inbox.source_id}"
    inbox_id = auth_token_params[:inbox_id] || @web_widget&.inbox&.id
    open_conversation = contact_inbox.conversations.where(inbox_id: inbox_id, status: [:open, :pending]).last
    
    if open_conversation
      Rails.logger.info "[Widget] ✅ Found fallback conversation: #{open_conversation.id}"
      update_redis_mapping_for_conversation(open_conversation)
      open_conversation
    else
      Rails.logger.info "[Widget] 🔍 No open conversations found for fallback"
      nil
    end
  end

  def find_conversation_via_database
    conversations_scope = conversations
    Rails.logger.info "[Widget] 🔍 Database lookup - open conversations: #{conversations_scope.where(status: [:open, :pending]).count}"
    
    conversation = conversations_scope.where(status: [:open, :pending]).last
    if conversation
      Rails.logger.info "[Widget] ✅ Found conversation via database: #{conversation.id}"
    else
      Rails.logger.info "[Widget] 🔍 Database lookup - no open conversations found"
    end
    
    conversation
  end

  def find_conversation_via_database_with_redis_storage
    conversations_scope = conversations
    Rails.logger.info "[Widget] 🔍 Database lookup - open conversations: #{conversations_scope.where(status: [:open, :pending]).count}"
    
    conversation = conversations_scope.where(status: [:open, :pending]).last
    if conversation
      Rails.logger.info "[Widget] ✅ Found conversation via database: #{conversation.id}"
      
      # Store in Redis for future lookups (only for conversation management operations)
      if should_store_in_redis?
        Rails.logger.info "[Widget] 💾 Storing database conversation #{conversation.id} in Redis for future lookups"
        store_conversation_in_redis(conversation)
      end
    else
      Rails.logger.info "[Widget] 🔍 Database lookup - no open conversations found"
    end
    
    conversation
  end

  def build_conversation_params_with_page_info
    base_params = conversation_params
    page_info = get_redis_page_info
    
    return base_params unless page_info.present?

    merge_page_info_into_params(base_params, page_info)
  end

  def get_redis_page_info
    return {} unless visitor_id.present?
    
    VisitorConversationMapping.get_page_info_for_visitor(visitor_id, @web_widget.website_token) || {}
  end

  def merge_page_info_into_params(base_params, page_info)
    existing_custom_attributes = base_params[:custom_attributes] || {}
    
    if existing_custom_attributes['page_url'].blank? && page_info[:page_url].present?
      base_params[:custom_attributes] = existing_custom_attributes.merge({
        'page_url' => page_info[:page_url],
        'page_title' => page_info[:page_title],
        'referer_url' => page_info[:referer_url]
      }.compact)
    end
    
    base_params
  end

  def should_store_in_redis?
    visitor_id.present? && @contact_inbox&.source_id.present?
  end

  def store_conversation_in_redis(conversation)
    return unless conversation

    Rails.logger.info "[Widget] 💾 Attempting to store conversation #{conversation.id} in Redis for visitor: #{visitor_id}"
    Rails.logger.info "[Widget] 💾 Contact_inbox source_id: #{@contact_inbox&.source_id}"
    Rails.logger.info "[Widget] 💾 Website token: #{@web_widget&.website_token}"

    conversation_token = generate_conversation_token_for_conversation(conversation)
    unless conversation_token
      Rails.logger.error "[Widget] ❌ Failed to generate conversation token for conversation #{conversation.id}"
      return
    end

    Rails.logger.info "[Widget] 💾 Generated conversation token successfully"
    
    # Store conversation token
    result1 = VisitorConversationMapping.set_conversation_for_visitor(visitor_id, @web_widget.website_token, conversation_token)
    Rails.logger.info "[Widget] 💾 Conversation token storage result: #{result1}"
    
    # Store contact mapping
    result2 = VisitorConversationMapping.set_contact_for_visitor(visitor_id, @web_widget.website_token, @contact_inbox.source_id)
    Rails.logger.info "[Widget] 💾 Contact mapping storage result: #{result2}"
    
    Rails.logger.info "[Widget] ✅ Completed storing conversation #{conversation.id} in Redis"
  end

  def update_redis_mapping_for_conversation(conversation)
    return unless should_store_in_redis?

    updated_token = generate_conversation_token_for_conversation(conversation)
    return unless updated_token

    VisitorConversationMapping.set_conversation_for_visitor(visitor_id, @web_widget.website_token, updated_token)
  end

  def generate_conversation_token_for_conversation(conversation)
    Rails.logger.info "[Widget] 🔑 Generating token for conversation #{conversation&.id}"
    Rails.logger.info "[Widget] 🔑 Prerequisites check..."
    
    unless conversation_token_prerequisites_met?(conversation)
      Rails.logger.error "[Widget] ❌ Token prerequisites not met for conversation #{conversation&.id}"
      Rails.logger.error "[Widget] ❌ Conversation present: #{conversation.present?}"
      Rails.logger.error "[Widget] ❌ Conversation ID: #{conversation&.id}"
      Rails.logger.error "[Widget] ❌ Contact_inbox source_id: #{@contact_inbox&.source_id}"
      Rails.logger.error "[Widget] ❌ Conversation inbox_id: #{conversation&.inbox_id}"
      return nil
    end
    
    payload = {
      source_id: @contact_inbox.source_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id
    }
    
    Rails.logger.info "[Widget] 🔑 Token payload: #{payload.inspect}"
    
    token = ::Widget::TokenService.new(payload: payload).generate_token
    Rails.logger.info "[Widget] ✅ Token generated successfully"
    token
  rescue StandardError => e
    Rails.logger.error "[Widget] ❌ Token generation exception: #{e.message}"
    Rails.logger.error "[Widget] ❌ Exception backtrace: #{e.backtrace.first(3).join(', ')}"
    nil
  end

  def conversation_token_prerequisites_met?(conversation)
    conversation&.id.present? && 
    @contact_inbox&.source_id.present? && 
    conversation.inbox_id.present?
  end

  def inbox
    @inbox ||= ::Inbox.find_by(id: auth_token_params[:inbox_id]) || @web_widget&.inbox
  end

  def conversation_params
    message_data = permitted_params[:message] || {}
    current_inbox = inbox
    
    raise "No inbox available for conversation creation" unless current_inbox
    
    {
      account_id: current_inbox.account_id,
      inbox_id: current_inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: build_additional_attributes,
      custom_attributes: build_custom_attributes(message_data)
    }
  end

  def build_additional_attributes
    {
      browser_language: browser.accept_language&.first&.code,
      browser: browser_params,
      initiated_at: timestamp_params
    }
  end

  def build_custom_attributes(message_data)
    {
      referer_url: message_data[:referer_url],
      page_url: message_data[:page_url],
      page_title: message_data[:page_title]
    }.compact.merge(permitted_params[:custom_attributes].presence || {})
  end

  def contact_email
    permitted_params.dig(:contact, :email)&.downcase
  end

  def contact_name
    return if @contact&.email.present? || @contact&.phone_number.present? || @contact&.identifier.present?

    permitted_params.dig(:contact, :name) || (contact_email.split('@')[0] if contact_email.present?)
  end

  def contact_phone_number
    permitted_params.dig(:contact, :phone_number)
  end

  def browser_params
    {
      browser_name: browser.name,
      browser_version: browser.full_version,
      device_name: browser.device.name,
      platform_name: browser.platform.name,
      platform_version: browser.platform.version
    }
  end

  def timestamp_params
    { triggered_at: Time.zone.now }
  end

  def visitor_id
    request.headers['X-Visitor-ID'] || permitted_params[:visitor_id]
  end

  def message_params
    message_data = permitted_params[:message] || {}
    current_conversation = conversation
    
    # Ensure we have a valid conversation object
    unless current_conversation.respond_to?(:account_id) && current_conversation.respond_to?(:inbox_id)
      Rails.logger.error "[Widget] Invalid conversation object for message_params: #{current_conversation.class}"
      return {}
    end
    
    return {} unless current_conversation.account_id && current_conversation.inbox_id
    
    {
      account_id: current_conversation.account_id,
      sender: @contact,
      content: message_data[:content],
      inbox_id: current_conversation.inbox_id,
      content_attributes: build_message_content_attributes(message_data),
      echo_id: message_data[:echo_id],
      message_type: :incoming
    }
  end

  def build_message_content_attributes(message_data)
    {
      in_reply_to: message_data[:reply_to],
      page_info: {
        page_url: message_data[:page_url],
        page_title: message_data[:page_title],
        referer_url: message_data[:referer_url]
      }.compact
    }.compact
  end

  def find_conversation_for_context
    # Determine if this request should trigger conversation lookup
    action_name = params[:action]
    controller_name = params[:controller]
    
    # Only perform full conversation lookup for specific actions that need it
    case "#{controller_name}##{action_name}"
    when 'api/v1/widget/conversations#index', 'api/v1/widget/conversations#create'
      # These actions need full conversation lookup with Redis
      find_or_build_conversation
    when 'api/v1/widget/messages#index', 'api/v1/widget/messages#create'
      # For message operations, try to use existing conversation without Redis lookup
      find_existing_conversation_without_redis
    else
      # For other actions, try lightweight lookup
      find_existing_conversation_without_redis
    end
  end

  def find_existing_conversation_without_redis
    # Try to find existing conversation without triggering Redis operations
    # This is for message operations where we should already have a conversation
    
    return nil unless @contact_inbox.present?
    
    Rails.logger.info "[Widget] 🔍 Lightweight conversation lookup for visitor: #{visitor_id}"
    
    # Try database lookup first (most common case for existing conversations)
    conversation_from_db = find_conversation_via_database
    if conversation_from_db
      Rails.logger.info "[Widget] ✅ Found existing conversation via database: #{conversation_from_db.id}"
      return conversation_from_db
    end
    
    # Only try Redis if database lookup fails AND we have visitor_id
    if visitor_id.present?
      Rails.logger.info "[Widget] 🔍 Database lookup failed, checking Redis for visitor: #{visitor_id}"
      conversation_from_redis = find_conversation_via_redis
      if conversation_from_redis
        Rails.logger.info "[Widget] ✅ Found conversation via Redis: #{conversation_from_redis.id}"
        return conversation_from_redis
      end
    end
    
    Rails.logger.warn "[Widget] ❌ No existing conversation found for visitor: #{visitor_id}"
    nil
  end
end
