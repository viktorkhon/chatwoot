class Api::V1::Widget::BaseController < ApplicationController
  include SwitchLocale
  include WebsiteTokenHelper

  before_action :set_web_widget
  before_action :set_contact

  private

  def conversations
    # Use the inbox_id from auth token if available, otherwise use the web widget's inbox
    inbox_id = auth_token_params[:inbox_id] || @web_widget&.inbox_id
    
    Rails.logger.info "[BaseController] Conversations lookup - inbox_id: #{inbox_id}, hmac_verified: #{@contact_inbox&.hmac_verified?}"
    
    if @contact_inbox.hmac_verified?
      verified_contact_inbox_ids = @contact.contact_inboxes.where(inbox_id: inbox_id, hmac_verified: true).map(&:id)
      @conversations = @contact.conversations.where(contact_inbox_id: verified_contact_inbox_ids)
      Rails.logger.info "[BaseController] HMAC verified path - found #{verified_contact_inbox_ids.count} verified contact inboxes"
    else
      @conversations = @contact_inbox.conversations.where(inbox_id: inbox_id)
      Rails.logger.info "[BaseController] Standard path - using contact_inbox #{@contact_inbox.id} for inbox #{inbox_id}"
    end
    @conversations
  end

  def conversation
    return @conversation if @conversation

    Rails.logger.info "[BaseController] === CONVERSATION LOOKUP START ==="
    Rails.logger.info "[BaseController] Visitor ID: #{visitor_id}"
    Rails.logger.info "[BaseController] Auth token present: #{auth_token_params.present?}"
    Rails.logger.info "[BaseController] Contact present: #{@contact&.id}"
    Rails.logger.info "[BaseController] Contact inbox present: #{@contact_inbox&.id}"

    # First try to get conversation from Redis mapping for incognito users
    if visitor_id.present?
      conversation_token = VisitorConversationMapping.get_conversation_for_visitor(visitor_id, @web_widget.website_token)
      Rails.logger.info "[BaseController] Redis conversation token for visitor #{visitor_id}: #{conversation_token.present? ? 'found' : 'not found'}"
      
      if conversation_token.present?
        # Validate the Redis mapping first
        if validate_redis_conversation_mapping(visitor_id, conversation_token)
          # Decode the conversation token to get the contact inbox
          begin
            token_data = ::Widget::TokenService.new(token: conversation_token).decode_token
            Rails.logger.info "[BaseController] Decoded token data: #{token_data}"
            
            if token_data[:source_id].present?
              # Find the contact inbox and its open conversations
              contact_inbox = @web_widget.inbox.contact_inboxes.find_by(source_id: token_data[:source_id])
              Rails.logger.info "[BaseController] Contact inbox found: #{contact_inbox&.id}"
              
              if contact_inbox
                # Ensure we're using the same contact_inbox for consistency
                if contact_inbox.id == @contact_inbox&.id
                  # If token has specific conversation_id, use it directly
                  if token_data[:conversation_id].present?
                    specific_conversation = contact_inbox.conversations.find_by(id: token_data[:conversation_id])
                    if specific_conversation && [:open, :pending].include?(specific_conversation.status.to_sym)
                      @conversation = specific_conversation
                      Rails.logger.info "[BaseController] ✅ Found specific conversation #{@conversation.id} for visitor #{visitor_id} via Redis"
                      return @conversation
                    end
                  end
                  
                  # Fallback to last open conversation
                  inbox_id = auth_token_params[:inbox_id] || @web_widget&.inbox_id
                  open_conversation = contact_inbox.conversations.where(inbox_id: inbox_id, status: [:open, :pending]).last
                  Rails.logger.info "[BaseController] Open conversation found via Redis: #{open_conversation&.id}"
                  
                  if open_conversation
                    @conversation = open_conversation
                    Rails.logger.info "[BaseController] ✅ Found existing conversation #{@conversation.id} for visitor #{visitor_id} via Redis"
                    
                    # Update Redis mapping to ensure it points to the correct conversation
                    updated_token = generate_conversation_token_for_conversation(@conversation)
                    if updated_token
                      VisitorConversationMapping.set_conversation_for_visitor(visitor_id, @web_widget.website_token, updated_token)
                      Rails.logger.info "[BaseController] Updated Redis mapping for visitor #{visitor_id} to conversation #{@conversation.id}"
                    end
                    
                    return @conversation
                  else
                    Rails.logger.info "[BaseController] Contact found but no open conversations for visitor #{visitor_id}"
                  end
                else
                  Rails.logger.warn "[BaseController] Contact inbox mismatch: Redis points to #{contact_inbox.id}, current is #{@contact_inbox&.id}"
                  # Clear stale mapping
                  VisitorConversationMapping.clear_visitor_data(visitor_id, @web_widget.website_token)
                end
              else
                Rails.logger.warn "[BaseController] Contact inbox not found for source_id #{token_data[:source_id]}"
                # Clear invalid mapping
                VisitorConversationMapping.clear_visitor_data(visitor_id, @web_widget.website_token)
              end
            end
          rescue => e
            Rails.logger.error "[BaseController] Error decoding conversation token: #{e.message}"
            # Clear invalid token from Redis
            VisitorConversationMapping.clear_visitor_data(visitor_id, @web_widget.website_token)
          end
        else
          Rails.logger.warn "[BaseController] Invalid Redis mapping detected, clearing for visitor #{visitor_id}"
          VisitorConversationMapping.clear_visitor_data(visitor_id, @web_widget.website_token)
        end
      end
    end

    # Fall back to the original logic - get the last conversation from conversations scope
    Rails.logger.info "[BaseController] Falling back to original conversation lookup"
    
    if @contact_inbox.present?
      # Use the same scope for consistency
      conversations_scope = conversations
      Rails.logger.info "[BaseController] Conversations scope class: #{conversations_scope.class}, SQL: #{conversations_scope.to_sql}" if conversations_scope.respond_to?(:to_sql)
      
      open_conversations = conversations_scope.where(status: [:open, :pending])
      all_conversations = conversations_scope
      Rails.logger.info "[BaseController] Found #{open_conversations.count} open conversations out of #{all_conversations.count} total conversations"
      inbox_id = auth_token_params[:inbox_id] || @web_widget&.inbox_id
      Rails.logger.info "[BaseController] Contact inbox ID: #{@contact_inbox.id}, Contact ID: #{@contact.id}, Inbox ID: #{inbox_id}"
      
      @conversation = open_conversations.last
      if @conversation
        Rails.logger.info "[BaseController] ✅ Found conversation #{@conversation.id} using original method"
        
        # Store this conversation in Redis for future lookups if we have a visitor ID
        if visitor_id.present? && @contact_inbox.source_id.present?
          conversation_token = generate_conversation_token_for_conversation(@conversation)
          if conversation_token
            VisitorConversationMapping.set_conversation_for_visitor(visitor_id, @web_widget.website_token, conversation_token)
            Rails.logger.info "[BaseController] Stored conversation #{@conversation.id} in Redis for visitor #{visitor_id}"
          end
        end
      else
        Rails.logger.warn "[BaseController] ❌ No open conversations found for contact inbox #{@contact_inbox.id}"
      end
    else
      Rails.logger.error "[BaseController] ❌ No contact inbox available for conversation lookup"
    end

    Rails.logger.info "[BaseController] === CONVERSATION LOOKUP END: #{@conversation&.id || 'nil'} ==="
    @conversation
  end



  def create_conversation
    # Get page info from Redis if available
    page_info = {}
    if visitor_id.present?
      redis_page_info = VisitorConversationMapping.get_page_info_for_visitor(visitor_id, @web_widget.website_token)
      page_info = redis_page_info if redis_page_info.present?
    end
    
    # Merge page info from Redis with current request params
    conversation_params_with_page_info = conversation_params
    if page_info.present?
      existing_custom_attributes = conversation_params_with_page_info[:custom_attributes] || {}
      
      if existing_custom_attributes['page_url'].blank? && page_info[:page_url].present?
        conversation_params_with_page_info[:custom_attributes] = existing_custom_attributes.merge({
          'page_url' => page_info[:page_url],
          'page_title' => page_info[:page_title],
          'referer_url' => page_info[:referer_url]
        }.compact)
      end
    end
    
    begin
      Rails.logger.info "[BaseController] Creating conversation with params: contact_id=#{conversation_params_with_page_info[:contact_id]}, contact_inbox_id=#{conversation_params_with_page_info[:contact_inbox_id]}, inbox_id=#{conversation_params_with_page_info[:inbox_id]}"
      new_conversation = ::Conversation.create!(conversation_params_with_page_info)
      Rails.logger.info "[BaseController] ✅ Conversation created successfully: ID=#{new_conversation.id}, contact_inbox_id=#{new_conversation.contact_inbox_id}, status=#{new_conversation.status}"
    rescue => e
      Rails.logger.error "[BaseController] Failed to create conversation: #{e.message}"
      raise e
    end
    
    # Store conversation token in Redis for incognito users
    if visitor_id.present? && @contact_inbox.source_id.present?
      conversation_token = generate_conversation_token_for_conversation(new_conversation)
      if conversation_token
        VisitorConversationMapping.set_conversation_for_visitor(visitor_id, @web_widget.website_token, conversation_token)
        VisitorConversationMapping.set_contact_for_visitor(visitor_id, @web_widget.website_token, @contact_inbox.source_id)
      end
    end
    
    new_conversation
  end

  def generate_conversation_token_for_conversation(conversation)
    return nil unless conversation && @contact_inbox
    
    begin
      ::Widget::TokenService.new(
        payload: {
          source_id: @contact_inbox.source_id,
          inbox_id: conversation.inbox_id,
          conversation_id: conversation.id  # Add conversation ID to token for validation
        }
      ).generate_token
    rescue => e
      Rails.logger.error "[BaseController] Error generating conversation token: #{e.message}"
      nil
    end
  end

  def validate_redis_conversation_mapping(visitor_id, conversation_token)
    return false unless visitor_id.present? && conversation_token.present?
    
    begin
      token_data = ::Widget::TokenService.new(token: conversation_token).decode_token
      return false unless token_data[:source_id].present?
      
      # Find the contact inbox
      contact_inbox = @web_widget.inbox.contact_inboxes.find_by(source_id: token_data[:source_id])
      return false unless contact_inbox
      
      # If token has conversation_id, validate it exists and is open
      if token_data[:conversation_id].present?
        conversation = contact_inbox.conversations.find_by(id: token_data[:conversation_id])
        if conversation.nil? || conversation.status == 'resolved'
          Rails.logger.warn "[BaseController] Redis mapping points to invalid/resolved conversation #{token_data[:conversation_id]}"
          return false
        end
      end
      
      true
    rescue => e
      Rails.logger.error "[BaseController] Error validating Redis mapping: #{e.message}"
      false
    end
  end

  def inbox
    @inbox ||= ::Inbox.find_by(id: auth_token_params[:inbox_id])
  end

  def conversation_params
    message_data = permitted_params[:message] || {}
    
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        browser_language: browser.accept_language&.first&.code,
        browser: browser_params,
        initiated_at: timestamp_params
      },
      custom_attributes: {
        referer_url: message_data[:referer_url],
        page_url: message_data[:page_url],
        page_title: message_data[:page_title]
      }.compact.merge(permitted_params[:custom_attributes].presence || {})
    }
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
    
    # Ensure conversation exists before accessing its properties
    return {} unless conversation&.account_id && conversation&.inbox_id
    
    {
      account_id: conversation.account_id,
      sender: @contact,
      content: message_data[:content],
      inbox_id: conversation.inbox_id,
      content_attributes: {
        in_reply_to: message_data[:reply_to],
        page_info: {
          page_url: message_data[:page_url],
          page_title: message_data[:page_title],
          referer_url: message_data[:referer_url]
        }.compact
      }.compact,
      echo_id: message_data[:echo_id],
      message_type: :incoming
    }
  end
end
