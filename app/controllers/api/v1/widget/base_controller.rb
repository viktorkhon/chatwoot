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
    @conversation ||= find_or_build_conversation
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
    return nil unless @contact_inbox.present?

    Rails.logger.info "[Widget] 🔍 Looking up conversation for visitor: #{visitor_id}, contact_inbox: #{@contact_inbox.source_id}"

    # Try Redis first for incognito users
    conversation_from_redis = find_conversation_via_redis
    if conversation_from_redis
      Rails.logger.info "[Widget] ✅ Using Redis conversation: #{conversation_from_redis.id}"
      return conversation_from_redis
    end

    Rails.logger.info "[Widget] 🔍 Redis lookup failed, trying database lookup..."
    
    # Fallback to database lookup
    conversation_from_db = find_conversation_via_database
    if conversation_from_db
      Rails.logger.info "[Widget] ✅ Using database conversation: #{conversation_from_db.id}"
      # Store in Redis for future lookups
      store_conversation_in_redis(conversation_from_db) if should_store_in_redis?
      return conversation_from_db
    end
    
    # Only log when no conversation is found - this is the critical issue
    Rails.logger.warn "[Widget] ❌ No conversation found for visitor: #{visitor_id}, contact_inbox: #{@contact_inbox.source_id}"
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
    
    if validate_redis_conversation_mapping(visitor_id, conversation_token)
      conversation = extract_conversation_from_token(conversation_token)
      if conversation.present?
        Rails.logger.info "[Widget] ✅ Found conversation via Redis: #{conversation.id}"
      else
        Rails.logger.warn "[Widget] ❌ Redis token validation passed but conversation extraction failed"
      end
      conversation
    else
      Rails.logger.warn "[Widget] ❌ Redis mapping validation failed - clearing stale mapping for visitor: #{visitor_id}"
      VisitorConversationMapping.clear_visitor_data(visitor_id, @web_widget.website_token)
      nil
    end
  end

  def extract_conversation_from_token(conversation_token)
    token_data = ::Widget::TokenService.new(token: conversation_token).decode_token
    return nil unless token_data[:source_id].present?

    contact_inbox = @web_widget.inbox.contact_inboxes.find_by(source_id: token_data[:source_id])
    return nil unless contact_inbox&.id == @contact_inbox&.id

    find_conversation_from_token_data(contact_inbox, token_data)
  rescue StandardError => e
    Rails.logger.error "[Widget] Token extraction failed: #{e.message}"
    nil
  end

  def find_conversation_from_token_data(contact_inbox, token_data)
    # Try specific conversation ID first
    if token_data[:conversation_id].present?
      specific_conversation = contact_inbox.conversations.find_by(id: token_data[:conversation_id])
      if specific_conversation&.open_or_pending?
        return specific_conversation
      end
    end

    # Fallback to last open conversation
    inbox_id = auth_token_params[:inbox_id] || @web_widget&.inbox&.id
    open_conversation = contact_inbox.conversations.where(inbox_id: inbox_id, status: [:open, :pending]).last
    
    if open_conversation
      update_redis_mapping_for_conversation(open_conversation)
      open_conversation
    end
  end

  def find_conversation_via_database
    conversations_scope = conversations
    Rails.logger.info "[Widget] 🔍 Database lookup - total conversations for contact_inbox #{@contact_inbox.source_id}: #{conversations_scope.count}"
    
    open_conversations = conversations_scope.where(status: [:open, :pending])
    Rails.logger.info "[Widget] 🔍 Database lookup - open conversations: #{open_conversations.count}"
    
    if open_conversations.any?
      Rails.logger.info "[Widget] 🔍 Database lookup - conversation IDs: #{open_conversations.pluck(:id).join(', ')}"
    end
    
    conversation = open_conversations.last
    if conversation
      Rails.logger.info "[Widget] 🔍 Database lookup - selected conversation: #{conversation.id}"
      Rails.logger.info "[Widget] ✅ Found conversation via database: #{conversation.id}"
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

    conversation_token = generate_conversation_token_for_conversation(conversation)
    return unless conversation_token

    Rails.logger.info "[Widget] 💾 Storing conversation #{conversation.id} in Redis for visitor: #{visitor_id}"
    VisitorConversationMapping.set_conversation_for_visitor(visitor_id, @web_widget.website_token, conversation_token)
    VisitorConversationMapping.set_contact_for_visitor(visitor_id, @web_widget.website_token, @contact_inbox.source_id)
  end

  def update_redis_mapping_for_conversation(conversation)
    return unless should_store_in_redis?

    updated_token = generate_conversation_token_for_conversation(conversation)
    return unless updated_token

    VisitorConversationMapping.set_conversation_for_visitor(visitor_id, @web_widget.website_token, updated_token)
  end

  def generate_conversation_token_for_conversation(conversation)
    return nil unless conversation_token_prerequisites_met?(conversation)
    
    ::Widget::TokenService.new(
      payload: {
        source_id: @contact_inbox.source_id,
        inbox_id: conversation.inbox_id,
        conversation_id: conversation.id
      }
    ).generate_token
  rescue StandardError => e
    Rails.logger.error "[Widget] Token generation failed: #{e.message}"
    nil
  end

  def conversation_token_prerequisites_met?(conversation)
    conversation&.id.present? && 
    @contact_inbox&.source_id.present? && 
    conversation.inbox_id.present?
  end

  def validate_redis_conversation_mapping(visitor_id, conversation_token)
    return false unless visitor_id.present? && conversation_token.present?
    
    begin
      token_data = ::Widget::TokenService.new(token: conversation_token).decode_token
      return false unless token_data[:source_id].present?
      
      Rails.logger.info "[Widget] 🔍 Validating Redis token - source_id: #{token_data[:source_id]}, conversation_id: #{token_data[:conversation_id]}"
      Rails.logger.info "[Widget] 🔍 Current contact_inbox source_id: #{@contact_inbox&.source_id}"
      
      # Use the current contact_inbox instead of looking up by source_id
      # This ensures we're validating against the correct contact_inbox
      contact_inbox = @contact_inbox
      return false unless contact_inbox
      
      # Check if the token's source_id matches the current contact_inbox
      if token_data[:source_id] != contact_inbox.source_id
        Rails.logger.warn "[Widget] ❌ Token source_id mismatch: token=#{token_data[:source_id]}, current=#{contact_inbox.source_id}"
        return false
      end

      result = validate_conversation_from_token(contact_inbox, token_data)
      Rails.logger.info "[Widget] 🔍 Redis validation result: #{result}"
      result
    rescue StandardError => e
      Rails.logger.error "[Widget] Redis mapping validation failed: #{e.message}"
      false
    end
  end

  def validate_conversation_from_token(contact_inbox, token_data)
    return true unless token_data[:conversation_id].present?

    conversation = contact_inbox.conversations.find_by(id: token_data[:conversation_id])
    Rails.logger.info "[Widget] 🔍 Validating conversation #{token_data[:conversation_id]}: found=#{conversation.present?}, status=#{conversation&.status}"
    
    conversation.present? && conversation.status != 'resolved'
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
    return {} unless conversation&.account_id && conversation&.inbox_id
    
    {
      account_id: conversation.account_id,
      sender: @contact,
      content: message_data[:content],
      inbox_id: conversation.inbox_id,
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
end
