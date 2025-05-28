class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController
  include Events::Types
  include DateRangeHelper
  include HmacConcern

  before_action :conversation, except: [:index, :meta, :search, :create, :filter]
  before_action :inbox, :contact, :contact_inbox, only: [:create]

  ATTACHMENT_RESULTS_PER_PAGE = 100

  def index
    result = conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def meta
    result = conversation_finder.perform
    @conversations_count = result[:count]
  end

  def search
    result = conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def attachments
    @attachments_count = @conversation.attachments.count
    @attachments = @conversation.attachments
                                .includes(:message)
                                .order(created_at: :desc)
                                .page(attachment_params[:page])
                                .per(ATTACHMENT_RESULTS_PER_PAGE)
  end

  def show; end

  def create
    # Log when conversation creation endpoint is called - this should NOT happen from n8n
    Rails.logger.warn "[🔍 CONVERSATION CREATE DEBUG] ⚠️  ConversationsController.create called - THIS CREATES NEW CONVERSATIONS!"
    Rails.logger.warn "[🔍 CONVERSATION CREATE DEBUG] ⚠️  Call stack trace:"
    caller.first(10).each_with_index do |line, index|
      Rails.logger.warn "[🔍 CONVERSATION CREATE DEBUG]   #{index + 1}. #{line}"
    end
    
    Rails.logger.warn "[🔍 CONVERSATION CREATE DEBUG] ⚠️  User: #{Current.user&.class} (#{Current.user&.id}), Account: #{Current.account&.id}"
    Rails.logger.warn "[🔍 CONVERSATION CREATE DEBUG] ⚠️  Request params: #{params.except(:controller, :action, :format).to_unsafe_h}"
    
    # Enhanced analysis for n8n webhook issue
    if Current.user.is_a?(AgentBot)
      Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ DUPLICATE CONVERSATION ISSUE: n8n is calling conversation CREATE endpoint instead of message CREATE endpoint!"
      Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ n8n should call: /conversations/{display_id}/messages"
      Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ n8n is calling: /conversations (this creates new conversations)"
      
      # Analyze if n8n is using a message ID instead of conversation ID
      if params[:source_id].present?
        # Check if this source_id corresponds to an existing conversation
        existing_conversation = Current.account.conversations.joins(:contact_inbox)
                                              .where(contact_inboxes: { source_id: params[:source_id] })
                                              .order(created_at: :desc).first
        
        if existing_conversation.present?
          Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ CRITICAL: Conversation already exists for source_id: #{params[:source_id]}"
          Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ Existing conversation ID: #{existing_conversation.id}, Display ID: #{existing_conversation.display_id}"
          Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ n8n should use display_id #{existing_conversation.display_id} in URL: /conversations/#{existing_conversation.display_id}/messages"
          
          # Check if there's a recent message_updated event for this conversation
          recent_message = existing_conversation.messages.order(created_at: :desc).first
          if recent_message.present? && recent_message.updated_at > 5.minutes.ago
            Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ SMOKING GUN: Recent message update detected!"
            Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ Message ID: #{recent_message.id}, Updated: #{recent_message.updated_at}"
            Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ n8n likely received message_updated webhook and is incorrectly using message ID (#{recent_message.id}) to create conversation!"
            Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ SOLUTION: n8n should use conversation.id from webhook payload, NOT top-level id (message ID)"
          end
        end
      end
      
      # Check if contact_id corresponds to existing conversations
      if params[:contact_id].present?
        existing_conversations = Current.account.conversations.where(contact_id: params[:contact_id])
                                               .order(created_at: :desc).limit(3)
        
        if existing_conversations.any?
          Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ Contact #{params[:contact_id]} already has #{existing_conversations.count} conversations:"
          existing_conversations.each_with_index do |conv, index|
            Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌   #{index + 1}. ID: #{conv.id}, Display ID: #{conv.display_id}, Status: #{conv.status}, Created: #{conv.created_at}"
          end
        end
      end
    end
    
    ActiveRecord::Base.transaction do
      @conversation = ConversationBuilder.new(params: params, contact_inbox: @contact_inbox).perform
      
      Rails.logger.warn "[🔍 CONVERSATION CREATE DEBUG] ⚠️  NEW conversation created - ID: #{@conversation.id}, Display ID: #{@conversation.display_id}, Contact: #{@conversation.contact.id}"
      
      Messages::MessageBuilder.new(Current.user, @conversation, params[:message]).perform if params[:message].present?
      
      Rails.logger.warn "[🔍 CONVERSATION CREATE DEBUG] ⚠️  Message added to new conversation - Conversation: #{@conversation.id}"
    end
    
    Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ DUPLICATE CONVERSATION CREATED - This is the root cause of the duplicate conversation issue!"
  end

  def update
    @conversation.update!(permitted_update_params)
  end

  def filter
    result = ::Conversations::FilterService.new(params.permit!, current_user, current_account).perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render_could_not_create_error(e.message)
  end

  def mute
    @conversation.mute!
    head :ok
  end

  def unmute
    @conversation.unmute!
    head :ok
  end

  def transcript
    render json: { error: 'email param missing' }, status: :unprocessable_entity and return if params[:email].blank?

    ConversationReplyMailer.with(account: @conversation.account).conversation_transcript(@conversation, params[:email])&.deliver_later
    head :ok
  end

  def toggle_status
    # FIXME: move this logic into a service object
    if pending_to_open_by_bot?
      @conversation.bot_handoff!
    elsif params[:status].present?
      set_conversation_status
      @status = @conversation.save!
    else
      @status = @conversation.toggle_status
    end
    assign_conversation if should_assign_conversation?
  end

  def pending_to_open_by_bot?
    return false unless Current.user.is_a?(AgentBot)

    @conversation.status == 'pending' && params[:status] == 'open'
  end

  def should_assign_conversation?
    @conversation.status == 'open' && Current.user.is_a?(User) && Current.user&.agent?
  end

  def toggle_priority
    @conversation.toggle_priority(params[:priority])
    head :ok
  end

  def toggle_typing_status
    typing_status_manager = ::Conversations::TypingStatusManager.new(@conversation, current_user, params)
    typing_status_manager.toggle_typing_status
    head :ok
  end

  def update_last_seen
    update_last_seen_on_conversation(DateTime.now.utc, assignee?)
  end

  def unread
    last_incoming_message = @conversation.messages.incoming.last
    last_seen_at = last_incoming_message.created_at - 1.second if last_incoming_message.present?
    update_last_seen_on_conversation(last_seen_at, true)
  end

  def custom_attributes
    @conversation.custom_attributes = params.permit(custom_attributes: {})[:custom_attributes]
    @conversation.save!
  end

  private

  def permitted_update_params
    # TODO: Move the other conversation attributes to this method and remove specific endpoints for each attribute
    params.permit(:priority)
  end

  def attachment_params
    params.permit(:page)
  end

  def update_last_seen_on_conversation(last_seen_at, update_assignee)
    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_column(:agent_last_seen_at, last_seen_at)
    @conversation.update_column(:assignee_last_seen_at, last_seen_at) if update_assignee.present?
    # rubocop:enable Rails/SkipsModelValidations
  end

  def set_conversation_status
    @conversation.status = params[:status]
    @conversation.snoozed_until = parse_date_time(params[:snoozed_until].to_s) if params[:snoozed_until]
  end

  def assign_conversation
    @conversation.assignee = current_user
    @conversation.save!
  end

  def conversation
    @conversation ||= Current.account.conversations.find_by!(display_id: params[:id])
    authorize @conversation.inbox, :show?
  end

  def inbox
    return if params[:inbox_id].blank?

    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end

  def contact
    return if params[:contact_id].blank?

    @contact = Current.account.contacts.find(params[:contact_id])
  end

  def contact_inbox
    @contact_inbox = build_contact_inbox

    # fallback for the old case where we do look up only using source id
    # In future we need to change this and make sure we do look up on combination of inbox_id and source_id
    # and deprecate the support of passing only source_id as the param
    @contact_inbox ||= ::ContactInbox.find_by!(source_id: params[:source_id])
    authorize @contact_inbox.inbox, :show?
  rescue ActiveRecord::RecordNotUnique
    render json: { error: 'source_id should be unique' }, status: :unprocessable_entity
  end

  def build_contact_inbox
    return if @inbox.blank? || @contact.blank?

    ContactInboxBuilder.new(
      contact: @contact,
      inbox: @inbox,
      source_id: params[:source_id],
      hmac_verified: hmac_verified?
    ).perform
  end

  def conversation_finder
    @conversation_finder ||= ConversationFinder.new(Current.user, params)
  end

  def assignee?
    @conversation.assignee_id? && Current.user == @conversation.assignee
  end
end

Api::V1::Accounts::ConversationsController.prepend_mod_with('Api::V1::Accounts::ConversationsController')
