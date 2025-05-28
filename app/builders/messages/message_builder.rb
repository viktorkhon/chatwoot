class Messages::MessageBuilder
  include ::FileTypeHelper
  attr_reader :message

  def initialize(user, conversation, params)
    @params = params
    @private = params[:private] || false
    @conversation = conversation
    @user = user
    @message_type = params[:message_type] || 'outgoing'
    @attachments = params[:attachments]

    # Extract content attributes once
    extracted_content_attributes = content_attributes

    # Determine the source of card data based on content_type and presence of keys
    # Prioritize :custom_cards, but fall back to :items if content_type is custom_cards
    if @params[:content_type] == 'custom_cards'
      @custom_cards_data = extracted_content_attributes&.dig(:custom_cards) || extracted_content_attributes&.dig(:items)
    else
      @custom_cards_data = extracted_content_attributes&.dig(:custom_cards)
    end

    @in_reply_to = extracted_content_attributes&.dig(:in_reply_to)
    # Note: Removed @items and @custom_cards initialization here as @custom_cards_data covers it
    @automation_rule = extracted_content_attributes&.dig(:automation_rule_id)
  end

  def perform
    Rails.logger.info "[CONVERSATION DEBUG] MessageBuilder.perform called"
    Rails.logger.info "[CONVERSATION DEBUG] Call stack trace:"
    caller.first(5).each_with_index do |line, index|
      Rails.logger.info "[CONVERSATION DEBUG]   #{index + 1}. #{line}"
    end
    
    Rails.logger.info "[CONVERSATION DEBUG] Creating message - Conversation: #{@conversation.id}, User: #{@user&.class}, Content: #{@params[:content]&.truncate(50)}"
    
    return if @conversation.lock!

    @message = @conversation.messages.create!(message_params)
    
    Rails.logger.info "[CONVERSATION DEBUG] Message created - ID: #{@message.id}, Type: #{@message.message_type}, Conversation: #{@conversation.id}"
    
    @message
  end

  private

  # Extracts content attributes from the given params.
  # - Converts ActionController::Parameters to a regular hash if needed.
  # - Attempts to parse a JSON string if content is a string.
  # - Returns an empty hash if content is not present, if there's a parsing error, or if it's an unexpected type.
  def content_attributes
    params = convert_to_hash(@params)
    content_attributes = params.fetch(:content_attributes, {})

    return parse_json(content_attributes) if content_attributes.is_a?(String)
    return content_attributes if content_attributes.is_a?(Hash)

    {}
  end

  # Converts the given object to a hash.
  # If it's an instance of ActionController::Parameters, converts it to an unsafe hash.
  # Otherwise, returns the object as-is.
  def convert_to_hash(obj)
    return obj.to_unsafe_h if obj.instance_of?(ActionController::Parameters)

    obj
  end

  # Attempts to parse a string as JSON.
  # If successful, returns the parsed hash with symbolized names.
  # If unsuccessful, returns nil.
  def parse_json(content)
    JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end

  def process_attachments
    return if @attachments.blank?

    @attachments.each do |uploaded_attachment|
      attachment = @message.attachments.build(
        account_id: @message.account_id,
        file: uploaded_attachment
      )

      attachment.file_type = if uploaded_attachment.is_a?(String)
                               file_type_by_signed_id(
                                 uploaded_attachment
                               )
                             else
                               file_type(uploaded_attachment&.content_type)
                             end
    end
  end

  def process_emails
    return unless @conversation.inbox&.inbox_type == 'Email'

    cc_emails = process_email_string(@params[:cc_emails])
    bcc_emails = process_email_string(@params[:bcc_emails])
    to_emails = process_email_string(@params[:to_emails])

    all_email_addresses = cc_emails + bcc_emails + to_emails
    validate_email_addresses(all_email_addresses)

    @message.content_attributes[:cc_emails] = cc_emails
    @message.content_attributes[:bcc_emails] = bcc_emails
    @message.content_attributes[:to_emails] = to_emails
  end

  def process_email_string(email_string)
    return [] if email_string.blank?

    email_string.gsub(/\s+/, '').split(',')
  end

  def validate_email_addresses(all_emails)
    all_emails&.each do |email|
      raise StandardError, 'Invalid email address' unless email.match?(URI::MailTo::EMAIL_REGEXP)
    end
  end

  def message_type
    if @conversation.inbox.channel_type != 'Channel::Api' && @message_type == 'incoming'
      raise StandardError, 'Incoming messages are only allowed in Api inboxes'
    end

    @message_type
  end

  def sender
    message_type == 'outgoing' ? (message_sender || @user) : @conversation.contact
  end

  def external_created_at
    @params[:external_created_at].present? ? { external_created_at: @params[:external_created_at] } : {}
  end

  def automation_rule_id
    @automation_rule.present? ? { content_attributes: { automation_rule_id: @automation_rule } } : {}
  end

  def campaign_id
    @params[:campaign_id].present? ? { additional_attributes: { campaign_id: @params[:campaign_id] } } : {}
  end

  def template_params
    @params[:template_params].present? ? { additional_attributes: { template_params: JSON.parse(@params[:template_params].to_json) } } : {}
  end

  def message_sender
    return if @params[:sender_type] != 'AgentBot'

    AgentBot.where(account_id: [nil, @conversation.account.id]).find_by(id: @params[:sender_id])
  end

  def process_custom_cards
    # Now checks @custom_cards_data instead of @custom_cards
    return unless @custom_cards_data

    # Set the message content type to custom_cards
    # This ensures the frontend knows how to render this message
    @message.content_type = 'custom_cards'
    
    # Create the content_attributes hash with structured items
    # Each item in items array will represent one card to display
    @message.content_attributes = {
      items: @custom_cards_data.map do |card|
        # Ensure card is a hash with symbolized keys for consistent access
        card_data = card.is_a?(Hash) ? card.deep_symbolize_keys : {}
        {
          # Core card fields - removed invalid id, created_at and updated_at fields
          title: card_data[:title],                  # Card title (required)
          description: card_data[:description],      # Card description (required)
          price: card_data[:price],                  # Price information (optional)
          image_url: card_data[:image_url],          # URL to card image (optional)
          reason: card_data[:reason],                # Reason for suggestion (optional)
          
          # Actions array - for buttons and interactive elements
          actions: card_data[:actions] || [],        # Array of action objects
          
          # Display options
          supports_markdown: card_data.fetch(:supports_markdown, true) # Whether to render markdown (defaults to true)
        }
      end
    }
  end

  def message_params
    initial_attributes = content_attributes.slice(:email, :items, :submitted_values, :in_reply_to, :automation_rule_id)
    
    # If process_custom_cards will run, it will overwrite content_attributes later.
    # If not, we might want to retain the initial :items if the content_type wasn't custom_cards initially.
    # However, the current logic seems fine: let process_custom_cards handle the definitive attributes for that type.

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type,
      content: @params[:content],
      private: @private,
      sender: sender,
      # Set content_type directly from params; process_custom_cards will override if needed.
      content_type: @params[:content_type],
      # Set initial content_attributes; process_custom_cards will override if needed.
      content_attributes: initial_attributes,
      source_id: @params[:source_id],
      echo_id: @params[:echo_id],
      additional_attributes: {}, # Placeholder, add specific logic if needed
      external_created_at: external_created_at.dig(:external_created_at),
    }.merge(campaign_id)
     .merge(template_params)
     .merge(automation_rule_id)
  end
end