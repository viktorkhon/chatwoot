import types from '../../mutation-types';

// mutations
export default {
  [types.ADD_MESSAGE](state, message) {
    const { id, status } = message;
    const conversation = state.allConversations.find(
      c => c.id === message.conversation_id
    );

    if (!conversation) return;

    const messageIds = conversation.messages.map(m => m.id);
    const indexInMessages = messageIds.indexOf(id);

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