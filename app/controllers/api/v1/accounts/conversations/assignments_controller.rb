class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  before_action :unwrap_body_params, only: [:create]

  def create
    Rails.logger.info("AssignmentsController#create called with params: #{params.inspect}")
    
    begin
      if params.key?(:assignee_id)
        set_agent
      elsif params.key?(:team_id)
        set_team
      else
        render json: { error: "Missing assignee_id or team_id parameter" }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error("Error in AssignmentsController#create: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # unassigns agent/team from a conversation
  def destroy
    Rails.logger.info("AssignmentsController#destroy called with params: #{params.inspect}")
    
    begin
      # Set explicitly_unassigned flag
      @conversation.additional_attributes = (@conversation.additional_attributes || {}).merge(
        explicitly_unassigned: true
      )
      
      # Unassign if there's an assignee
      if @conversation.assignee.present?
        @conversation.assignee = nil
      end
      
      # Unassign team if present
      if @conversation.team.present?
        @conversation.team = nil
      end
      
      @conversation.save!
      
      render json: { status: 'success', message: 'Conversation unassigned successfully' }
    rescue => e
      Rails.logger.error("Error in AssignmentsController#destroy: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def set_agent
    @agent = Current.account.users.find_by(id: params[:assignee_id])
    
    # If we're setting agent to nil (unassigning), set the explicitly_unassigned flag
    if params[:assignee_id] == '0' || params[:assignee_id] == 0
      @conversation.additional_attributes = (@conversation.additional_attributes || {}).merge(
        explicitly_unassigned: true
      )
    elsif @conversation.additional_attributes.is_a?(Hash) && @conversation.additional_attributes['explicitly_unassigned']
      # If we're assigning to a specific agent, clear the explicitly_unassigned flag
      @conversation.additional_attributes = @conversation.additional_attributes.except('explicitly_unassigned')
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
