class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    Rails.logger.debug "BaseController#conversation - All params: #{params.inspect}"
    Rails.logger.debug "BaseController#conversation - conversation_id: #{params[:conversation_id]}"
    Rails.logger.debug "BaseController#conversation - id: #{params[:id]}"
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize @conversation
  end
end
