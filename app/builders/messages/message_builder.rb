class Messages::MessageBuilder
  include ::FileTypeHelper
  attr_reader :message

  def initialize(user, conversation, params)
    @params = params
    @private = params[:private] || false
    @conversation = conversation # Assumes conversation is always non-nil here
    @user = user
    @message_type = params[:message_type] || 'outgoing'
    @attachments = params[:attachments]
    @automation_rule = content_attributes&.dig(:automation_rule_id)

    return unless params.instance_of?(ActionController::Parameters)

    @in_reply_to = content_attributes&.dig(:in_reply_to)
    @items = content_attributes&.dig(:items)
  end

  def perform
    @message = @conversation.messages.build(message_params)
    process_attachments 
    process_emails 
    @message.save!
    @message
  end

  private

  def content_attributes
    params = convert_to_hash(@params)
    content_attributes = params.fetch(:content_attributes, {})

    return parse_json(content_attributes) if content_attributes.is_a?(String)
    return content_attributes if content_attributes.is_a?(Hash)

    {}
  end

  def convert_to_hash(obj)
    return obj.to_unsafe_h if obj.instance_of?(ActionController::Parameters)

    obj
  end

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
  def validate_email_addresses(all_emails) 

  def message_type
    if @conversation.inbox&.channel_type != 'Channel::Api' && @message_type == 'incoming'
      raise StandardError, 'Incoming messages are only allowed in Api inboxes'
    end

    @message_type
  end

  def sender
    message_type == 'outgoing' ? (message_sender || @user) : @conversation&.contact
  end

  def external_created_at 
  def automation_rule_id 
  def campaign_id 
  def template_params 

  def message_sender
    return if @params[:sender_type] != 'AgentBot'
    AgentBot.where(account_id: [nil, @conversation&.account&.id]).find_by(id: @params[:sender_id])
  end

  def message_params
    processed_attributes = content_attributes

    params_hash = {
      account_id: @conversation&.account_id,
      inbox_id: @conversation&.inbox_id,
      message_type: message_type,
      content: @params[:content],
      private: @private,
      sender: sender,
      content_type: @params[:content_type],
      content_attributes: processed_attributes,
      echo_id: @params[:echo_id],
      source_id: @params[:source_id]
    }

    params_hash.deep_merge!(external_created_at)
    params_hash.deep_merge!(campaign_id)
    params_hash.deep_merge!(template_params)

    if @automation_rule.present?
      params_hash[:content_attributes] ||= {} 
      params_hash[:content_attributes][:automation_rule_id] = @automation_rule
    end

    params_hash
  end
end
