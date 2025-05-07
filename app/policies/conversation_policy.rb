class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end
  
  def show?
    true
  end
  
  def create?
    true
  end
  
  def update?
    true
  end
  
  # Authorization for assignments is handled through this method
  # Used for "create" action in AssignmentsController
  def create_assignment?
    # Anyone who can see the conversation can assign it
    true
  end
  
  # Check if user has proper inbox access
  def user_has_inbox_access?
    # Allow if user is admin or agent with access to the inbox
    return true if user.administrator?
    
    # For agents, check if they are a member of the inbox
    if user.agent?
      record.inbox.members.include?(user)
    else
      false
    end
  end
end
