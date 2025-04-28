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
      conversation.messages.push(message);
    } else {
      // Replace or update the message if it exists
      const existingMessage = conversation.messages[indexInMessages];
      // Merge new data into existing message, ensuring reactivity
      conversation.messages[indexInMessages] = { ...existingMessage, ...message };
      // Explicitly update status if provided
      if (status !== undefined) {
        conversation.messages[indexInMessages].status = status;
      }
    }
  }
}; 