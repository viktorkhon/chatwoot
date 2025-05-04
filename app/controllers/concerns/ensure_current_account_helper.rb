module EnsureCurrentAccountHelper
  private

  def current_account
    @current_account ||= ensure_current_account
    Current.account = @current_account
  end

  def ensure_current_account
    account = Account.find(params[:account_id])
    render_unauthorized('Account is suspended') and return unless account.active?

    if current_user
      account_accessible_for_user?(account)
    elsif @resource.is_a?(AgentBot)
      account_accessible_for_bot?(account)
    end
    account
  end

  def account_accessible_for_user?(account)
    @current_account_user = account.account_users.find_by(user_id: current_user.id)
    Current.account_user = @current_account_user
    render_unauthorized('You are not authorized to access this account') unless @current_account_user
  end

  def account_accessible_for_bot?(account)
    # Log the bot access attempt for debugging
    Rails.logger.info("Agent bot #{@resource.id} (#{@resource.name}) attempting to access account #{account.id}")
    
    # Check if the bot has any inbox in this account
    has_access = @resource.agent_bot_inboxes.where(account_id: account.id).exists?
    
    if !has_access
      Rails.logger.error("Access denied: Bot #{@resource.id} has no associated inboxes in account #{account.id}")
      render_unauthorized('Bot is not authorized to access this account')
    else
      Rails.logger.info("Access granted: Bot #{@resource.id} has access to account #{account.id}")
    end
  end
end
