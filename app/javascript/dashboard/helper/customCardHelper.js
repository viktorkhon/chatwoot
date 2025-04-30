import { isCustomCardMessage } from 'shared/helpers/MessageTypeHelper';
import MarkdownIt from 'markdown-it';

/**
 * Markdown configuration for rendering rich text in custom cards
 * 
 * Settings:
 * - html: Allow HTML tags in the source
 * - xhtmlOut: Use '/' to close single tags (e.g. <br />)
 * - breaks: Convert '\n' in paragraphs into <br>
 * - linkify: Autoconvert URL-like text to links
 * - typographer: Enable smartquotes and other typographic replacements
 * - quotes: Define quotes for typographer
 */
const md = new MarkdownIt({
  html: true,
  xhtmlOut: true,
  breaks: true,
  linkify: true,
  typographer: true,
  quotes: '\u201c\u201d\u2018\u2019',
});

/**
 * Extracts the items array from a message's content_attributes
 * 
 * @param {Object} message - The message object
 * @returns {Array} - Array of card items, or empty array if none found
 */
export const getCustomCardsFromMessage = message => {
  // First validate that this is a custom_cards message type
  if (!isCustomCardMessage(message)) {
    return [];
  }
  // Return the items array from content_attributes, or empty array if not found
  return message.content_attributes?.items || [];
};

/**
 * Standardizes the format of custom cards data
 * 
 * This ensures all required fields are present and consistently named
 * across different data sources.
 * 
 * @param {Array} customCards - Array of card objects 
 * @returns {Array} - Formatted array of card objects
 */
export const formatCustomCardData = customCards => {
  if (!Array.isArray(customCards)) {
    return [];
  }
  return customCards.map(card => ({
    id: card.id,
    title: card.title,
    description: card.description,
    price: card.price,
    image_url: card.image_url,
    reason: card.reason,
    actions: card.actions || [],
    created_at: card.created_at,
    updated_at: card.updated_at,
    supports_markdown: card.supports_markdown || false,
  }));
};

/**
 * Validates that a card has the required fields
 * 
 * @param {Object} card - Card object to validate
 * @returns {Boolean} - Whether the card is valid
 */
export const validateCustomCard = card => {
  if (!card) {
    return false;
  }
  const requiredFields = ['title', 'description'];
  return requiredFields.every(field => card[field]);
};

/**
 * Renders markdown text as HTML if markdown is supported
 * 
 * @param {String} text - Text to render, possibly containing markdown
 * @param {Boolean} supportsMarkdown - Whether markdown should be rendered
 * @returns {String} - HTML string or original text
 */
export const renderMarkdown = (text, supportsMarkdown = true) => {
  if (!text || !supportsMarkdown) {
    return text;
  }
  return md.render(text);
};

/**
 * Gets the type of a card action
 * 
 * @param {Object} action - Action object
 * @returns {String|null} - Action type or null
 */
export const getCustomCardActionType = action => {
  if (!action) {
    return null;
  }
  return action.type || 'button';
};

/**
 * Gets the display label for a card action
 * 
 * @param {Object} action - Action object
 * @returns {String} - Action label or empty string
 */
export const getCustomCardActionLabel = action => {
  if (!action) {
    return '';
  }
  return action.label || '';
};

/**
 * Gets the value for a card action
 * 
 * @param {Object} action - Action object
 * @returns {String} - Action value or empty string
 */
export const getCustomCardActionValue = action => {
  if (!action) {
    return '';
  }
  return action.value || '';
}; 