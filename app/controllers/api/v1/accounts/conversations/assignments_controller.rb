class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  def create
    Rails.logger.info("Assignment attempt by #{Current.user.class.name} #{Current.user.id} with params: #{params.inspect}")
    
    # Handle nested params from assignment hash if present
    if params[:assignment].present? && params[:assignment][:team_id].present?
      params[:team_id] = params[:assignment][:team_id]
    elsif params[:assignment].present? && params[:assignment][:assignee_id].present?
      params[:assignee_id] = params[:assignment][:assignee_id]
    end
    
    if params.key?(:assignee_id)
      set_agent
    elsif params.key?(:team_id)
      set_team
    else
      render json: nil
    end
  end

  # unassigns agent/team from a conversation
  def destroy
    # Unassign agent if present
    if @conversation.assignee.present?
      # Set explicitly_unassigned flag
      @conversation.additional_attributes = @conversation.additional_attributes.merge(
        explicitly_unassigned: true
      )
      @conversation.assignee = nil
      @conversation.save!
    end

    # Unassign team if present
    if @conversation.team.present?
      @conversation.team = nil
      @conversation.save!
    end

    render json: { status: 'success', message: 'Conversation unassigned' }
  end

  private

  def set_agent
    # Handle unassignment (assignee_id = 0)
    if params[:assignee_id] == '0' || params[:assignee_id] == 0
      @agent = nil
      @conversation.additional_attributes = (@conversation.additional_attributes || {}).merge(
        explicitly_unassigned: true
      )
    else
      @agent = Current.account.users.find_by(id: params[:assignee_id])
      
      # If assigning to agent, remove explicitly_unassigned flag
      if @agent.present? && @conversation.additional_attributes.is_a?(Hash) && @conversation.additional_attributes['explicitly_unassigned']
        @conversation.additional_attributes = @conversation.additional_attributes.except('explicitly_unassigned')
      end
    end
    
    @conversation.assignee = @agent
    @conversation.save!
    render_agent
  end

  def render_agent
    if @agent.nil?
      render json: nil
    else
      render partial: 'api/v1/models/agent', formats: [:json], locals: { resource: @agent }
    end
  end

  def set_team
    @team = Current.account.teams.find_by(id: params[:team_id])
    @conversation.update!(team: @team)
    render json: @team
  end
end
