class ConversationListener < BaseListener
  def conversation_created(event)
    conversation = event.data[:conversation]
    
    # If custom_attributes already has page information, nothing to do
    return if conversation.custom_attributes.present? && 
              conversation.custom_attributes['page_url'].present?
    
    # Extract contact to find recent webwidget events
    contact = conversation.contact
    contact_inbox = conversation.contact_inbox
    
    # Check if there's event data with page info
    event_info = event.data[:event_info]
    if event_info.present? && event_info[:page_url].present?
      Rails.logger.debug "ConversationListener - Adding page_url=#{event_info[:page_url]} to conversation #{conversation.id} from event_info"
      
      # Update the conversation custom attributes with page info from event
      conversation.custom_attributes = conversation.custom_attributes.merge(
        'page_url' => event_info[:page_url],
        'page_title' => event_info[:page_title],
        'referer_url' => event_info[:referer]
      )
      conversation.save!
      return
    end
    
    # Get the latest message that might have page info
    message = conversation.messages.where.not(message_type: :activity).order(created_at: :desc).first
    if message&.content_attributes.present? && message.content_attributes['page_info'].present?
      page_info = message.content_attributes['page_info']
      
      # Parse if it's a string
      if page_info.is_a?(String)
        begin
          page_info = if page_info.include?('=>')
                        eval(page_info)
                      else
                        JSON.parse(page_info)
                      end
        rescue => e
          Rails.logger.error "Error parsing page_info: #{e.message}"
        end
      end
      
      if page_info.is_a?(Hash) && page_info['page_url'].present?
        Rails.logger.debug "ConversationListener - Adding page_url=#{page_info['page_url']} to conversation #{conversation.id} from message"
        
        # Update the conversation custom attributes with page info
        conversation.custom_attributes = conversation.custom_attributes.merge(
          'page_url' => page_info['page_url'],
          'page_title' => page_info['page_title'],
          'referer_url' => page_info['referer_url']
        )
        conversation.save!
      end
    end
  end
end 