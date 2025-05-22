class Api::V1::Widget::ConversationsController < Api::V1::Widget::BaseController
  include Events::Types
  before_action :render_not_found_if_empty, only: [:toggle_typing, :toggle_status, :set_custom_attributes, :destroy_custom_attributes]
  before_action :check_visitor_id, only: [:index, :create]

  def index
    @conversation = conversation
  end

  def create
    # Check if visitor already has a conversation in Redis
    existing_conversation_id = VisitorConversationMapping.get_conversation_id(visitor_id) if visitor_id
    
    if existing_conversation_id && Conversation.where(id: existing_conversation_id).exists?
      # Use existing conversation if found
      @conversation = Conversation.find(existing_conversation_id)
      conversation.messages.create!(message_params)
      conversation.reload
    else
      # Create new conversation and store mapping
      ActiveRecord::Base.transaction do
        process_update_contact
        @conversation = create_conversation
        conversation.messages.create!(message_params)
        # TODO: Temporary fix for message type cast issue, since message_type is returning as string instead of integer
        conversation.reload
        
        # Store visitor-conversation mapping if visitor ID is present
        if visitor_id
          VisitorConversationMapping.set_mapping(visitor_id, conversation.id)
        end
      end
    end
  end

  def process_update_contact
    @contact = ContactIdentifyAction.new(
      contact: @contact,
      params: { email: contact_email, phone_number: contact_phone_number, name: contact_name },
      retain_original_contact_name: true,
      discard_invalid_attrs: true
    ).perform
  end

  def update_last_seen
    head :ok && return if conversation.nil?

    conversation.contact_last_seen_at = DateTime.now.utc
    conversation.save!
    ::Conversations::UpdateMessageStatusJob.perform_later(conversation.id, conversation.contact_last_seen_at)
    head :ok
  end

  def transcript
    if conversation.present? && conversation.contact.present? && conversation.contact.email.present?
      ConversationReplyMailer.with(account: conversation.account).conversation_transcript(
        conversation,
        conversation.contact.email
      )&.deliver_later
    end
    head :ok
  end

  def toggle_typing
    case permitted_params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON)
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF)
    end

    head :ok
  end

  def toggle_status
    unless conversation.resolved?
      conversation.status = :resolved
      # Clear conversation state when ending chat
      conversation.messages.destroy_all
      conversation.custom_attributes = {}
      conversation.save!
      
      # Clear any existing cookies and Redis mappings
      cookies.delete(:cw_conversation)
      cookies.delete(:cw_contact)
      VisitorConversationMapping.delete_mapping(visitor_id) if visitor_id
    end
    head :ok
  end

  def set_custom_attributes
    conversation.update!(custom_attributes: permitted_params[:custom_attributes])
  end

  def destroy_custom_attributes
    conversation.custom_attributes = conversation.custom_attributes.excluding(params[:custom_attribute])
    conversation.save!
    render json: conversation
  end

  private

  def trigger_typing_event(event)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: conversation, user: @contact)
  end

  def render_not_found_if_empty
    return head :not_found if conversation.nil?
  end
  
  def visitor_id
    request.headers['X-Visitor-ID']
  end
  
  def check_visitor_id
    # If we have a visitor ID but no conversation cookie, try to find by visitor ID
    if visitor_id && !cookies[:cw_conversation]
      conversation_id = VisitorConversationMapping.get_conversation_id(visitor_id)
      cookies[:cw_conversation] = conversation_id if conversation_id
    end
  end

  def permitted_params
    params.permit(:id, :typing_status, :website_token, :email, contact: [:name, :email, :phone_number],
                                                               message: [:content, :referer_url, :timestamp, :echo_id],
                                                               custom_attributes: {})
  end
end
