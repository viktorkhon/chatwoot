class Api::V1::Accounts::Conversations::CustomCardsController < Api::V1::Accounts::Conversations::BaseController
  CUSTOM_CARD_ACTION = 'custom_card_action'.freeze

  def create
    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform
    
    # Emit event for custom card creation
    Rails.configuration.dispatcher.dispatch(
      CUSTOM_CARD_ACTION,
      Time.zone.now,
      conversation: @conversation,
      message: @message
    )
    
    render json: @message
  rescue StandardError => e
    Rails.logger.error "CustomCardsController#create - Error: #{e.message}\n#{e.backtrace.join("\n")}"
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
  rescue StandardError => e
    Rails.logger.error "CustomCardsController#handle_action - Error: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def conversation
    @conversation ||= Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize @conversation.inbox, :show?
  end
end 