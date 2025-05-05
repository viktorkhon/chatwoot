class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  before_action :unwrap_body_params, only: [:create]
  def create
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
    @agent = Current.account.users.find_by(id: params[:assignee_id])
    @conversation.assignee = @agent
    
    # Set explicitly_unassigned flag when the assignee is nil
    if @agent.nil?
      @conversation.additional_attributes = @conversation.additional_attributes.merge(
        explicitly_unassigned: true
      )
    elsif @conversation.additional_attributes.is_a?(Hash)
      # If assigning to a new agent, remove the flag
      @conversation.additional_attributes = @conversation.additional_attributes.except('explicitly_unassigned')
    end
    
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
