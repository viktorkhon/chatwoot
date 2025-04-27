class Api::V1::Accounts::Conversations::CustomCardsController < Api::V1::Accounts::Conversations::BaseController
  CUSTOM_CARD_ACTION = 'custom_card_action'.freeze

  def create
    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform
    
    # Broadcast the message creation event via ActionCable
    Rails.logger.info "--- CustomCardsController: Before broadcast. Message ID: #{@message&.id}, Content Type: #{@message&.content_type}"
    ConversationChannel.broadcast_to(@conversation, :message_created, @message)
    Rails.logger.info "--- CustomCardsController: After broadcast. Message ID: #{@message&.id}"
    
    # Ensure message is immediately sent (especially important for bot messages)
    SendReplyJob.perform_now(@message.id) if @message.outgoing?
    
    render json: { message: @message, status: 'success' }
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def handle_action
    action = params[:action]
    card = params[:card]

    # Emit event for custom card action
    Rails.configuration.dispatcher.dispatch(
      CUSTOM_CARD_ACTION,
      Time.zone.now,
      conversation: @conversation,
      action: action,
      card: card
    )

    render json: { status: 'success' }
  end

  private

  def conversation
    @conversation ||= Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize @conversation.inbox, :show?
  end
end 