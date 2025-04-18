class Api::V1::Accounts::Conversations::CustomCardsController < Api::V1::Accounts::Conversations::BaseController
  CUSTOM_CARD_ACTION = 'custom_card_action'.freeze

  def create
    Rails.logger.debug "CustomCardsController#create - params: #{params.inspect}"
    Rails.logger.debug "CustomCardsController#create - @conversation: #{@conversation.inspect}"
    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform
    
    render json: @message
  rescue StandardError => e
    Rails.logger.error "CustomCardsController#create - Error: #{e.message}\n#{e.backtrace.join("\n")}"
    render_could_not_create_error(e.message)
  end

  def handle_action
    Rails.logger.debug "CustomCardsController#handle_action - params: #{params.inspect}"
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
    Rails.logger.debug "CustomCardsController#conversation - params: #{params.inspect}"
    if params[:id].blank?
      Rails.logger.error "CustomCardsController#conversation - Conversation ID is blank in params"
      raise ActiveRecord::RecordNotFound, "Couldn't find Conversation with display_id=NULL"
    end
    
    begin
      @conversation ||= Current.account.conversations.find_by!(display_id: params[:id])
      Rails.logger.debug "CustomCardsController#conversation - Found conversation: #{@conversation.display_id}"
      authorize @conversation.inbox, :show?
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "CustomCardsController#conversation - Could not find conversation with display_id=#{params[:id]}"
      raise
    end
  end
end 