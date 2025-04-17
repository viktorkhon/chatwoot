class Api::V1::Accounts::Conversations::CustomCardsController < Api::V1::Accounts::Conversations::BaseController
  CUSTOM_CARD_ACTION = 'custom_card_action'.freeze

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
      sender: Current.user || @resource
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
end 