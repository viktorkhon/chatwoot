# This Builder will create a contact and contact inbox with specified attributes.
# If an existing identified contact exisits, it will be returned.
# for contact inbox logic it uses the contact inbox builder

class ContactInboxWithContactBuilder
  pattr_initialize [:inbox!, :contact_attributes!, :source_id, :hmac_verified]

  def perform
    find_or_create_contact_and_contact_inbox
  # in case of race conditions where contact is created by another thread
  # we will try to find the contact and create a contact inbox
  rescue ActiveRecord::RecordNotUnique
    find_or_create_contact_and_contact_inbox
  end

  def find_or_create_contact_and_contact_inbox
    # Log the full call stack to identify what's triggering this contact inbox lookup/creation
    Rails.logger.info "[🔍 CONTACT DEBUG] ContactInboxWithContactBuilder.find_or_create_contact_and_contact_inbox called"
    Rails.logger.info "[🔍 CONTACT DEBUG] Call stack trace:"
    caller.first(10).each_with_index do |line, index|
      Rails.logger.info "[🔍 CONTACT DEBUG]   #{index + 1}. #{line}"
    end
    
    Rails.logger.info "[🔍 CONTACT DEBUG] Looking for existing contact_inbox with source_id: #{source_id}"
    
    @contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id) if source_id.present?
    
    if @contact_inbox
      Rails.logger.info "[🔍 CONTACT DEBUG] Found existing contact_inbox - ID: #{@contact_inbox.id}, Contact: #{@contact_inbox.contact.id}, Source: #{@contact_inbox.source_id}"
      return @contact_inbox
    end

    Rails.logger.info "[🔍 CONTACT DEBUG] No existing contact_inbox found, creating new one - Source: #{source_id}, Inbox: #{inbox.id}"
    
    ActiveRecord::Base.transaction(requires_new: true) do
      build_contact_with_contact_inbox
    end
    
    Rails.logger.info "[🔍 CONTACT DEBUG] Created new contact_inbox - ID: #{@contact_inbox.id}, Contact: #{@contact_inbox.contact.id}, Source: #{@contact_inbox.source_id}"
    
    update_contact_avatar(@contact) unless @contact.avatar.attached?
    @contact_inbox
  end

  private

  def build_contact_with_contact_inbox
    Rails.logger.info "[🔍 CONTACT DEBUG] Building contact with contact_inbox - Inbox: #{@inbox.id}, Contact attributes: #{contact_attributes.except(:avatar_url)}"
    
    @contact = find_contact || create_contact
    
    if @contact.persisted? && @contact.id.present?
      Rails.logger.info "[🔍 CONTACT DEBUG] Using existing contact - ID: #{@contact.id}, Email: #{@contact.email}, Phone: #{@contact.phone_number}"
    else
      Rails.logger.info "[🔍 CONTACT DEBUG] Created new contact - ID: #{@contact.id}, Email: #{@contact.email}, Phone: #{@contact.phone_number}"
    end
    
    @contact_inbox = create_contact_inbox
    Rails.logger.info "[🔍 CONTACT DEBUG] Created contact_inbox - ID: #{@contact_inbox.id}, Contact: #{@contact.id}, Source: #{@source_id}"
  end

  def account
    @account ||= inbox.account
  end

  def create_contact_inbox
    ContactInboxBuilder.new(
      contact: @contact,
      inbox: @inbox,
      source_id: @source_id,
      hmac_verified: hmac_verified
    ).perform
  end

  def update_contact_avatar(contact)
    ::Avatar::AvatarFromUrlJob.perform_later(contact, contact_attributes[:avatar_url]) if contact_attributes[:avatar_url]
  end

  def create_contact
    account.contacts.create!(
      name: contact_attributes[:name] || ::Haikunator.haikunate(1000),
      phone_number: contact_attributes[:phone_number],
      email: contact_attributes[:email],
      identifier: contact_attributes[:identifier],
      additional_attributes: contact_attributes[:additional_attributes],
      custom_attributes: contact_attributes[:custom_attributes]
    )
  end

  def find_contact
    contact = find_contact_by_identifier(contact_attributes[:identifier])
    contact ||= find_contact_by_email(contact_attributes[:email])
    contact ||= find_contact_by_phone_number(contact_attributes[:phone_number])
    contact ||= find_contact_by_instagram_source_id(source_id) if instagram_channel?

    contact
  end

  def instagram_channel?
    inbox.channel_type == 'Channel::Instagram'
  end

  # There might be existing contact_inboxes created through Channel::FacebookPage
  # with the same Instagram source_id. New Instagram interactions should create fresh contact_inboxes
  # while still reusing contacts if found in Facebook channels so that we can create
  # new conversations with the same contact.
  def find_contact_by_instagram_source_id(instagram_id)
    return if instagram_id.blank?

    existing_contact_inbox = ContactInbox.joins(:inbox)
                                         .where(source_id: instagram_id)
                                         .where(
                                           'inboxes.channel_type = ? AND inboxes.account_id = ?',
                                           'Channel::FacebookPage',
                                           account.id
                                         ).first

    existing_contact_inbox&.contact
  end

  def find_contact_by_identifier(identifier)
    return if identifier.blank?

    account.contacts.find_by(identifier: identifier)
  end

  def find_contact_by_email(email)
    return if email.blank?

    account.contacts.from_email(email)
  end

  def find_contact_by_phone_number(phone_number)
    return if phone_number.blank?

    account.contacts.find_by(phone_number: phone_number)
  end
end
