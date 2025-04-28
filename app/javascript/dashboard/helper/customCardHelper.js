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

export const renderMarkdown = (text, supportsMarkdown = false) => {
  if (!text) return '';
  return supportsMarkdown ? md.render(text) : text;
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

// Make this helper available globally for debugging
if (typeof window !== 'undefined') {
  window.fixAllCustomCardMessages = function() {
    console.log('Running fixAllCustomCardMessages...');
    try {
      // Get all messages from Vuex store
      const store = window?.__NUXT__?.state?.conversations;
      if (!store) {
        console.log('Store not found');
        return 'Store not found';
      }
      
      // Find all conversation messages
      let fixedCount = 0;
      let foundCustomCards = 0;
      
      // 1. Check for messages directly in the DOM
      const messageElements = document.querySelectorAll('li[id^="message"]');
      console.log(`Found ${messageElements.length} message elements in DOM`);
      
      // 2. Find messages in the Vuex store
      const allConversations = Object.values(store?.conversations || {});
      console.log(`Found ${allConversations.length} conversations in store`);
      
      // Force a refresh of all messages by temporarily modifying and restoring their content
      allConversations.forEach(conversation => {
        const messages = conversation?.messages || [];
        messages.forEach(message => {
          if (message.content_type === 'custom_cards') {
            foundCustomCards++;
            // Force Vue to update by changing content_attributes reference
            if (message.content_attributes) {
              const originalItems = message.content_attributes.items;
              if (originalItems) {
                message.content_attributes = {
                  ...message.content_attributes,
                  items: [...originalItems]
                };
                fixedCount++;
              }
            }
          }
        });
      });
      
      // 3. Try to force UI refresh
      if (window.$nuxt) {
        window.$nuxt.$forceUpdate();
      }
      
      return `Fixed ${fixedCount} custom card messages (found ${foundCustomCards} total)`;
    } catch (error) {
      console.error('Error in fixAllCustomCardMessages:', error);
      return `Error: ${error.message}`;
    }
  };
} 