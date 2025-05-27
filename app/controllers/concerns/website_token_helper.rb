module WebsiteTokenHelper
  def auth_token_params
    return @auth_token_params if defined?(@auth_token_params)
    
    auth_token = request.headers['X-Auth-Token']
    if auth_token.present?
      begin
        @auth_token_params = ::Widget::TokenService.new(token: auth_token).decode_token
      rescue => e
        Rails.logger.warn "[WebsiteTokenHelper] Failed to decode auth token: #{e.message}"
        @auth_token_params = {}
      end
    else
      @auth_token_params = {}
    end
    
    @auth_token_params
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    @current_account = @web_widget.inbox.account

    render json: { error: 'Account is suspended' }, status: :unauthorized unless @current_account.active?
  end

  def set_contact
    Rails.logger.info "[WebsiteTokenHelper] 🔍 SET_CONTACT - Starting contact resolution for visitor: #{visitor_id}"
    Rails.logger.info "[WebsiteTokenHelper] 🔍 SET_CONTACT - Auth token source_id: #{auth_token_params[:source_id]}"
    
    # First try to find contact using auth token
    if auth_token_params[:source_id].present?
      @contact_inbox = @web_widget.inbox.contact_inboxes.find_by(
        source_id: auth_token_params[:source_id]
      )
      @contact = @contact_inbox&.contact
      Rails.logger.info "[WebsiteTokenHelper] 🔍 SET_CONTACT - Found via auth token: contact_inbox=#{@contact_inbox&.source_id}, contact=#{@contact&.id}"
    end

    # If no contact found via auth token and we have a visitor ID, try Redis mapping
    if @contact.blank? && visitor_id.present?
      Rails.logger.info "[WebsiteTokenHelper] 🔍 SET_CONTACT - No auth token contact, checking Redis for visitor: #{visitor_id}"
      contact_source_id = VisitorConversationMapping.get_contact_for_visitor(visitor_id, @web_widget.website_token)
      
      if contact_source_id.present?
        Rails.logger.info "[WebsiteTokenHelper] 🔍 SET_CONTACT - Found Redis contact mapping: #{contact_source_id}"
        @contact_inbox = @web_widget.inbox.contact_inboxes.find_by(source_id: contact_source_id)
        @contact = @contact_inbox&.contact
        Rails.logger.info "[WebsiteTokenHelper] ✅ Found contact via Redis mapping for visitor #{visitor_id}: contact_inbox=#{@contact_inbox&.source_id}, contact=#{@contact&.id}"
      else
        Rails.logger.info "[WebsiteTokenHelper] 🔍 SET_CONTACT - No Redis contact mapping found for visitor: #{visitor_id}"
      end
    end

    # If still no contact, create a new one
    if @contact.blank?
      Rails.logger.warn "[WebsiteTokenHelper] ⚠️ Creating new contact for visitor #{visitor_id}"
      @contact_inbox = @web_widget.create_contact_inbox(additional_attributes)
      @contact = @contact_inbox.contact
      Rails.logger.info "[WebsiteTokenHelper] ✅ Created new contact: contact_inbox=#{@contact_inbox.source_id}, contact=#{@contact.id}"
      
      # Store the contact mapping for incognito users
      if visitor_id.present?
        VisitorConversationMapping.set_contact_for_visitor(visitor_id, @web_widget.website_token, @contact_inbox.source_id)
        Rails.logger.info "[WebsiteTokenHelper] ✅ Stored contact mapping for visitor #{visitor_id} -> #{@contact_inbox.source_id}"
      end
    else
      Rails.logger.info "[WebsiteTokenHelper] ✅ Using existing contact: contact_inbox=#{@contact_inbox&.source_id}, contact=#{@contact&.id}"
    end

    Current.contact = @contact
  end

  def visitor_id
    request.headers['X-Visitor-ID'] || permitted_params[:visitor_id]
  end

  def additional_attributes
    if @web_widget.inbox.account.feature_enabled?('ip_lookup')
      { created_at_ip: request.remote_ip }
    else
      {}
    end
  end

  def permitted_params
    params.permit(:website_token, :visitor_id, :id, :before, :after, 
                  contact: [:name, :email, :phone_number],
                  message: [:content, :referer_url, :page_url, :page_title, :timestamp, :echo_id, :reply_to, 
                           { content_attributes: { page_info: [:referer_url, :page_url, :page_title] } }],
                  custom_attributes: {})
  end
end
