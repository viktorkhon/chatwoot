import types from '../../mutation-types';
import { CONTENT_TYPES } from 'shared/constants/contentType';

// mutations
export default {
  [types.ADD_MESSAGE](state, message) {
    const { id, status, content_type } = message;
    const conversation = state.allConversations.find(
      c => c.id === message.conversation_id
    );

    if (!conversation) return;

    const messageIds = conversation.messages.map(m => m.id);
    const indexInMessages = messageIds.indexOf(id);

    // Special handling for custom_cards messages
    if (content_type === 'custom_cards') {
      console.log('[Vuex Mutation] Adding custom_cards message ID=' + id + ' to conversation ' + conversation.id);
      console.log('[Vuex Mutation] Message items:', message.content_attributes?.items);
      
      // Handle new or existing message
      if (indexInMessages === -1) {
        // Add new message, ensuring content_type is set
        const customCardMessage = {
          ...message,
          content_type: 'custom_cards', // Explicitly set
        };
        conversation.messages.push(customCardMessage);
        console.log('[Vuex Mutation] Added new custom_cards message. Total messages:', conversation.messages.length);
      } else {
        // Update existing message
        conversation.messages[indexInMessages] = {
          ...conversation.messages[indexInMessages],
          ...message,
          content_type: 'custom_cards', // Explicitly ensure this is set
        };
        console.log('[Vuex Mutation] Updated existing custom_cards message');
      }
      return; // Exit after handling custom_cards
    }

    if (indexInMessages === -1) {
      // Add new message
      conversation.messages.push(message);
    } else {
      // Update existing message
      // Merge new data into existing message, ensuring reactivity
      // Note: Direct array element assignment is reactive in Vue 3
      conversation.messages[indexInMessages] = {
        ...conversation.messages[indexInMessages], // Keep existing properties
        ...message, // Overwrite with new properties
      };
      // Ensure status is explicitly updated if provided
      if (status !== undefined) {
        conversation.messages[indexInMessages].status = status;
      }
    }
  }
}; 