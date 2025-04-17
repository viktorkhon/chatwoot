import { MESSAGE_TYPE } from 'shared/constants/messages';

export const isAFormMessage = message => message.content_type === 'form';
export const isASubmittedFormMessage = (message = {}) =>
  isAFormMessage(message) && !!message.content_attributes?.submitted_values;

export const MESSAGE_MAX_LENGTH = {
  GENERAL: 10000,
  FACEBOOK: 1000,
  TWILIO_SMS: 320,
  TWILIO_WHATSAPP: 1600,
  EMAIL: 25000,
};

export const isCustomCardMessage = message => {
  return message.content_type === 'custom_cards';
};

export const isOutgoingMessage = message => {
  return message.message_type === MESSAGE_TYPE.OUTGOING;
};

export const isIncomingMessage = message => {
  return message.message_type === MESSAGE_TYPE.INCOMING;
};

export const isTemplateMessage = message => {
  return message.content_type === 'template';
};

export const isPrivateNote = message => {
  return message.private;
};

export const isActivityMessage = message => {
  return message.activity;
};

export const isBotMessage = message => {
  return message.content_type === 'bot';
};

export const isInputMessage = message => {
  return message.content_type === 'input_select';
};

export const isArticleMessage = message => {
  return message.content_type === 'article';
};

export const isCardMessage = message => {
  return message.content_type === 'cards';
};
