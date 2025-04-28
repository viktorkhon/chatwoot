class ContentAttributeValidator < ActiveModel::Validator
  ALLOWED_SELECT_ITEM_KEYS = [:title, :value].freeze
  ALLOWED_CARD_ITEM_KEYS = [:title, :description, :media_url, :actions, :price].freeze
  ALLOWED_CUSTOM_CARD_ITEM_KEYS = [:title, :description, :image_url, :actions, :price, :supports_markdown, :reason, :custom_fields].freeze
  ALLOWED_CARD_ITEM_ACTION_KEYS = [:text, :type, :payload, :uri].freeze
  ALLOWED_FORM_ITEM_KEYS = [:type, :placeholder, :label, :name, :options, :default, :required, :pattern, :title, :pattern_error].freeze
  ALLOWED_ARTICLE_KEYS = [:title, :description, :link].freeze
  
  CONTENT_TYPE_INPUT_SELECT = 'input_select'.freeze
  CONTENT_TYPE_CARDS = 'cards'.freeze
  CONTENT_TYPE_CUSTOM_CARDS = 'custom_cards'.freeze
  CONTENT_TYPE_FORM = 'form'.freeze
  CONTENT_TYPE_ARTICLE = 'article'.freeze

  def validate(record)
    case record.content_type
    when CONTENT_TYPE_INPUT_SELECT
      validate_items!(record)
      validate_item_attributes!(record, ALLOWED_SELECT_ITEM_KEYS)
    when CONTENT_TYPE_CARDS
      validate_items!(record)
      validate_item_attributes!(record, ALLOWED_CARD_ITEM_KEYS)
      validate_item_actions!(record)
    when CONTENT_TYPE_CUSTOM_CARDS
      validate_items!(record)
      validate_item_attributes!(record, ALLOWED_CUSTOM_CARD_ITEM_KEYS)
      validate_item_actions!(record)
    when CONTENT_TYPE_FORM
      validate_items!(record)
      validate_item_attributes!(record, ALLOWED_FORM_ITEM_KEYS)
    when CONTENT_TYPE_ARTICLE
      validate_items!(record)
      validate_item_attributes!(record, ALLOWED_ARTICLE_KEYS)
    end
  end

  private

  def validate_items!(record)
    record.errors.add(:content_attributes, 'At least one item is required.') if record.items.blank?
    record.errors.add(:content_attributes, 'Items should be a hash.') if record.items.reject { |item| item.is_a?(Hash) }.present?
  end

  def validate_item_attributes!(record, valid_keys)
    item_keys = record.items.collect(&:keys).flatten.filter_map(&:to_sym)
    invalid_keys = item_keys - valid_keys
    record.errors.add(:content_attributes, "contains invalid keys for items : #{invalid_keys}") if invalid_keys.present?
  end

  def validate_item_actions!(record)
    if record.items.select { |item| item[:actions].blank? }.present?
      record.errors.add(:content_attributes, 'contains items missing actions') && return
    end

    validate_item_action_attributes!(record)
  end

  def validate_item_action_attributes!(record)
    item_action_keys = record.items.collect { |item| item[:actions].collect(&:keys) }
    invalid_keys = item_action_keys.flatten.compact.map(&:to_sym) - ALLOWED_CARD_ITEM_ACTION_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for actions:  #{invalid_keys}") if invalid_keys.present?
  end
end