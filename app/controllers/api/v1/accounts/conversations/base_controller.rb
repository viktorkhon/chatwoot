class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    Rails.logger.debug "BaseController#conversation - params: #{params.inspect}"
    Rails.logger.debug "BaseController#conversation - Current.account: #{Current.account.inspect}"
    @conversation ||= Current.account.conversations.find_by!(display_id: params[:id])
    Rails.logger.debug "BaseController#conversation - Found conversation: #{@conversation.inspect}"
    authorize @conversation.inbox, :show?
  end
end
