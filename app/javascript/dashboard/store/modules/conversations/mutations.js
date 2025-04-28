import types from '../../mutation-types';

// mutations
export default {
  [types.ADD_MESSAGE](state, message) {
    const { id, status, message_type: type } = message;
    const messagesInSameChat = state.allConversations.find(
      conversation => conversation.id === message.conversation_id
    );

    // Handle custom_cards specially to ensure proper Vue reactivity
    if (message.content_type === 'custom_cards' && message.content_attributes?.items) {
      // Create new references to trigger reactivity
      message = {
        ...message,
        content_attributes: {
          ...message.content_attributes,
          items: [...message.content_attributes.items]
        }
      };
    }

    if (!messagesInSameChat) return;

    const messageIds = messagesInSameChat.messages.map(m => m.id);
    const indexInMessage = messageIds.indexOf(id);

    if (indexInMessage === -1) {
      messagesInSameChat.messages.push(message);
      return;
    }

    if (status !== undefined) {
      messagesInSameChat.messages[indexInMessage].status = status;
    }

    messagesInSameChat.messages[indexInMessage] = message;
  }
}; 