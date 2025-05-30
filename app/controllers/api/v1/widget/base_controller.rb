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
    Conversation.none
  end

  def conversation
    @conversation ||= find_conversation_for_context
  end

  def create_conversation
    
    conversation_params_data = build_conversation_params_with_page_info
    new_conversation = ::Conversation.create!(conversation_params_data)
    store_conversation_in_redis(new_conversation) if should_store_in_redis?
    
    new_conversation
  rescue StandardError => e
    raise
  end

  # Core conversation lookup logic - this is the key method that needs to work properly
  def find_or_build_conversation
    
    # Try Redis first for incognito users - this works even when @contact_inbox is nil
    conversation_from_redis = find_conversation_via_redis
    if conversation_from_redis
      
      # CRITICAL: If we found a conversation via Redis but don't have @contact_inbox set,
      # we need to set it based on the conversation we found
      if @contact_inbox.nil?
        @contact_inbox = conversation_from_redis.contact_inbox
        @contact = @contact_inbox.contact
      end
      
      return conversation_from_redis
    end
    
    # For database lookup, we need @contact_inbox to be set
    return nil unless @contact_inbox.present?
    
    # Fallback to database lookup (this now automatically stores in Redis)
    conversation_from_db = find_conversation_via_database_with_redis_storage
    if conversation_from_db
      return conversation_from_db
    end
    
    nil
  end

  def find_conversation_via_redis
    return nil unless visitor_id.present?
    
    conversation_token = VisitorConversationMapping.get_conversation_for_visitor(visitor_id, @web_widget.website_token)
    
    # Combined validation and extraction to eliminate redundancy
    conversation = validate_and_extract_conversation_from_token(visitor_id, conversation_token)
    
    if conversation.present?
      
      # CRITICAL: If we found a conversation via Redis but don't have @contact_inbox set,
      # we need to set it based on the conversation we found
      if @contact_inbox.nil?
        @contact_inbox = conversation.contact_inbox
        @contact = @contact_inbox.contact
      end
      
      conversation
    else
      VisitorConversationMapping.clear_visitor_data(visitor_id, @web_widget.website_token)
      nil
    end
  end

  def validate_and_extract_conversation_from_token(visitor_id, conversation_token)
    return nil unless visitor_id.present? && conversation_token.present?
    
    # Ensure conversation_token is a string
    unless conversation_token.is_a?(String)
      return nil
    end
    
    begin
      
      # Decode token once
      token_data = ::Widget::TokenService.new(token: conversation_token).decode_token
      
      return nil unless token_data[:source_id].present?
      
      
      # Find contact_inbox from token
      contact_inbox = @web_widget.inbox.contact_inboxes.find_by(source_id: token_data[:source_id])
      unless contact_inbox
        return nil
      end
      
      # If we have a current contact_inbox, verify it matches the token
      if @contact_inbox.present? && token_data[:source_id] != @contact_inbox.source_id
        return nil
      end

      # Extract conversation from token data
      conversation = extract_conversation_from_token_data(contact_inbox, token_data)
      
      conversation
    rescue StandardError => e
      nil
    end
  end

  def extract_conversation_from_token_data(contact_inbox, token_data)
    # Try specific conversation ID first
    if token_data[:conversation_id].present?
      specific_conversation = contact_inbox.conversations.find_by(id: token_data[:conversation_id])
      
      if specific_conversation.present?
        if specific_conversation.status != 'resolved'
          return specific_conversation
        end
      end
    end

    # Fallback to last open conversation
    inbox_id = auth_token_params[:inbox_id] || @web_widget&.inbox&.id
    open_conversation = contact_inbox.conversations.where(inbox_id: inbox_id, status: [:open, :pending]).last
    
    if open_conversation
      update_redis_mapping_for_conversation(open_conversation)
      open_conversation
    else
      nil
    end
  end

  def find_conversation_via_database
    conversations_scope = conversations
    
    conversation = conversations_scope.where(status: [:open, :pending]).last
    
    conversation
  end

  def find_conversation_via_database_with_redis_storage
    conversations_scope = conversations
    
    conversation = conversations_scope.where(status: [:open, :pending]).last
    if conversation
      
      # Store in Redis for future lookups (only for conversation management operations)
      if should_store_in_redis?
        store_conversation_in_redis(conversation)
      end
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
    unless conversation_token
      return
    end
    
    # Store conversation token
    result1 = VisitorConversationMapping.set_conversation_for_visitor(visitor_id, @web_widget.website_token, conversation_token)
    
    # Store contact mapping
    result2 = VisitorConversationMapping.set_contact_for_visitor(visitor_id, @web_widget.website_token, @contact_inbox.source_id)
  end

  def update_redis_mapping_for_conversation(conversation)
    return unless should_store_in_redis?

    updated_token = generate_conversation_token_for_conversation(conversation)
    return unless updated_token

    VisitorConversationMapping.set_conversation_for_visitor(visitor_id, @web_widget.website_token, updated_token)
  end

  def generate_conversation_token_for_conversation(conversation)
    
    unless conversation_token_prerequisites_met?(conversation)
      return nil
    end
    
    payload = {
      source_id: @contact_inbox.source_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id
    }
    
    token = ::Widget::TokenService.new(payload: payload).generate_token
    token
  rescue StandardError => e
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

  def build_message_params_for_conversation(conversation)
    message_data = permitted_params[:message] || {}
    
    # Ensure we have a valid conversation object
    unless conversation.respond_to?(:account_id) && conversation.respond_to?(:inbox_id)
      return {}
    end
    
    return {} unless conversation.account_id && conversation.inbox_id
    
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
      find_existing_conversation_without_redis
    end
  end

  def find_existing_conversation_without_redis
    # Try to find existing conversation using ONLY database lookup
    # This is for message operations where we should already have a conversation
    # NO Redis operations to maximize performance
    
    return nil unless @contact_inbox.present?
    
    # Database lookup only - no Redis fallback for message operations
    conversation_from_db = find_conversation_via_database
    if conversation_from_db
      return conversation_from_db
    end
    nil
  end
end
