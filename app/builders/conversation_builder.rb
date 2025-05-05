class ConversationBuilder
  pattr_initialize [:params!, :contact_inbox!]

  def perform
    look_up_exising_conversation || create_new_conversation
  end

  private

  def look_up_exising_conversation
    return unless @contact_inbox.inbox.lock_to_single_conversation?

    @contact_inbox.conversations.last
  end

  def create_new_conversation
    conversation_params_with_page_info = conversation_params.dup
    
    # Check if custom_attributes already has page URL info
    custom_attributes = conversation_params_with_page_info[:custom_attributes] || {}
    string_keys_custom_attrs = custom_attributes.stringify_keys
    
    if string_keys_custom_attrs['page_url'].blank?
      # Try to get page info from Redis cache using contact_inbox source_id
      redis_key = "contact_inbox:#{@contact_inbox.source_id}:page_info"
      
      $alfred.with do |conn|
        cached_page_info = conn.get(redis_key)
        
        if cached_page_info.present?
          begin
            # Parse the cached page info
            page_info = JSON.parse(cached_page_info, symbolize_names: true)
            
            # Log that we found cached page info
            Rails.logger.info "ConversationBuilder - Found cached page info for #{@contact_inbox.source_id}: #{page_info}"
            
            # Add the page info to custom_attributes using string keys
            string_keys_custom_attrs['page_url'] = page_info[:page_url]
            string_keys_custom_attrs['page_title'] = page_info[:page_title]
            string_keys_custom_attrs['referer_url'] = page_info[:referer_url]
            
            # Update custom_attributes in the conversation params
            conversation_params_with_page_info[:custom_attributes] = string_keys_custom_attrs
          rescue => e
            Rails.logger.error "ConversationBuilder - Error parsing cached page info: #{e.message}"
          end
        end
      end
    end
    
    ::Conversation.create!(conversation_params_with_page_info)
  end

  def conversation_params
    additional_attributes = params[:additional_attributes]&.permit! || {}
    custom_attributes = params[:custom_attributes]&.permit! || {}
    status = params[:status].present? ? { status: params[:status] } : {}

    # TODO: temporary fallback for the old bot status in conversation, we will remove after couple of releases
    # commenting this out to see if there are any errors, if not we can remove this in subsequent releases
    # status = { status: 'pending' } if status[:status] == 'bot'
    {
      account_id: @contact_inbox.inbox.account_id,
      inbox_id: @contact_inbox.inbox_id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: additional_attributes,
      custom_attributes: custom_attributes,
      snoozed_until: params[:snoozed_until],
      assignee_id: params[:assignee_id],
      team_id: params[:team_id]
    }.merge(status)
  end
end
