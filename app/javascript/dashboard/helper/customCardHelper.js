import { isCustomCardMessage } from 'shared/helpers/MessageTypeHelper';
import MarkdownIt from 'markdown-it';

const md = new MarkdownIt({
  html: true,
  xhtmlOut: true,
  breaks: true,
  linkify: true,
  typographer: true,
  quotes: '\u201c\u201d\u2018\u2019',
});

export const getCustomCardsFromMessage = message => {
  if (!isCustomCardMessage(message)) {
    return [];
  }
  return message.content_attributes?.items || [];
};

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
    actions: card.actions || [],
    created_at: card.created_at,
    updated_at: card.updated_at,
    supports_markdown: card.supports_markdown || false,
  }));
};

export const validateCustomCard = card => {
  if (!card) {
    return false;
  }
  const requiredFields = ['title', 'description'];
  return requiredFields.every(field => card[field]);
};

export const renderMarkdown = (text, supportsMarkdown = true) => {
  if (!text || !supportsMarkdown) {
    return text;
  }
  return md.render(text);
};

export const getCustomCardActionType = action => {
  if (!action) {
    return null;
  }
  return action.type || 'button';
};

export const getCustomCardActionLabel = action => {
  if (!action) {
    return '';
  }
  return action.label || '';
};

export const getCustomCardActionValue = action => {
  if (!action) {
    return '';
  }
  return action.value || '';
}; 