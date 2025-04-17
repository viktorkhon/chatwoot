class Api::V1::Accounts::Conversations::CustomCardsController < Api::BaseController
  CUSTOM_CARD_ACTION = 'custom_card_action'.freeze

  before_action :set_conversation
  before_action :check_authorization

  def create
    @message = @conversation.messages.create!(
      content: params[:content],
      content_type: 'custom_cards',
      content_attributes: {
        items: params[:custom_cards].map do |card|
          {
            title: card[:title],
            description: card[:description],
            price: card[:price],
            image_url: card[:image_url],
            actions: card[:actions] || [],
            supports_markdown: card[:supports_markdown] != false
          }
        end
      },
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      sender: current_user
    )

    render json: @message
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

  def set_conversation
    @conversation = current_account.conversations.find(params[:conversation_id])
  end

  def check_authorization
    authorize(@conversation)
  end
end 