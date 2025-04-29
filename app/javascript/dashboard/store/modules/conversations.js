// Search for where new messages are received and add our interceptor

// Look for mutations like addMessage, setCurrentChat, etc.
// Add the following near these mutations:

// EMERGENCY DEBUG FUNCTION
const emergencyDebugMessage = message => {
  // Check if this is a message with items that should be a custom card
  if (message && message.content_attributes && message.content_attributes.items && message.content_attributes.items.length) {
    console.log('%c[STORE INTERCEPTOR] Message with items detected:', 'background:#f44336;color:white;padding:3px 6px;border-radius:3px;', {
      id: message.id,
      content_type: message.content_type,
      items_count: message.content_attributes.items.length
    });
    
    // If it has items but wrong content type, fix it
    if (message.content_type !== 'custom_cards') {
      console.warn('%c[STORE INTERCEPTOR] Fixing message content_type to custom_cards', 
        'background:#ff9800;color:black;padding:3px 6px;border-radius:3px;');
      
      // Clone the message to avoid mutating it directly
      const fixedMessage = JSON.parse(JSON.stringify(message));
      fixedMessage.content_type = 'custom_cards';
      
      console.log('[STORE INTERCEPTOR] Fixed message:', fixedMessage);
      return fixedMessage;
    }
  }
  return message;
};

// Find the mutation that adds messages to the conversation
// Usually it's named addMessage or updateMessageInConversation
// Add the emergencyDebugMessage call before the message is added:

// Example of how to modify an existing mutation:
// addMessage($state, message) {
//   const fixedMessage = emergencyDebugMessage(message);
//   // ... existing code that adds the message
// },

// Look for a mutation that adds messages and modify it to use our interceptor 