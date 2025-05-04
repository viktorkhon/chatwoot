class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  def create
    # Extract parameters from nested body if present
    if params[:body].present?
      assignment_params = params[:body]
    else
      assignment_params = params
    end

    if assignment_params.key?(:assignee_id)
      set_agent(assignment_params)
    elsif assignment_params.key?(:team_id)
      set_team(assignment_params)
    else
      render json: nil
    end
  end

  private

  def set_agent(assignment_params)
    @agent = Current.account.users.find_by(id: assignment_params[:assignee_id])
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

  def set_team(assignment_params)
    @team = Current.account.teams.find_by(id: assignment_params[:team_id])
    @conversation.update!(team: @team)
    render json: @team
  end
end
