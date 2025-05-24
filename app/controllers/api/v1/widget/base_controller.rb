class Api::V1::Widget::BaseController < ApplicationController
  include SwitchLocale
  include WebsiteTokenHelper

  before_action :set_web_widget
  before_action :set_contact

  private

  def conversations
    if @contact_inbox.hmac_verified?
      verified_contact_inbox_ids = @contact.contact_inboxes.where(inbox_id: auth_token_params[:inbox_id], hmac_verified: true).map(&:id)
      @conversations = @contact.conversations.where(contact_inbox_id: verified_contact_inbox_ids)
    else
      @conversations = @contact_inbox.conversations.where(inbox_id: auth_token_params[:inbox_id])
    end
  end

  def conversation
    return @conversation if @conversation

    # First try to get conversation from Redis mapping for incognito users
    if visitor_id.present?
      conversation_token = VisitorConversationMapping.get_conversation_for_visitor(visitor_id, @web_widget.website_token)
      if conversation_token.present?
        # Decode the conversation token to get the contact inbox
        begin
          token_data = ::Widget::TokenService.new(token: conversation_token).decode_token
          if token_data[:source_id].present?
            # Find the contact inbox and conversation
            contact_inbox = @web_widget.inbox.contact_inboxes.find_by(source_id: token_data[:source_id])
            if contact_inbox&.conversations&.last&.open?
              @conversation = contact_inbox.conversations.last
              Rails.logger.info "[BaseController] Found existing conversation #{@conversation.id} for visitor #{visitor_id}"
              return @conversation
            end
          end
        rescue => e
          Rails.logger.error "[BaseController] Error decoding conversation token: #{e.message}"
        end
      end
    end

    # Fall back to the original logic
    @conversation = conversations.last
  end

  def has_existing_conversation?
    conversation.present?
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
      new_conversation = ::Conversation.create!(conversation_params_with_page_info)
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
          inbox_id: conversation.inbox_id
        }
      ).generate_token
    rescue => e
      Rails.logger.error "[BaseController] Error generating conversation token: #{e.message}"
      nil
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
