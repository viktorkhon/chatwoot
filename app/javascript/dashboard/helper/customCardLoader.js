// This file is responsible for ensuring custom_cards are properly rendered
// by automatically fixing any reactivity issues with them

const initCustomCardFixer = () => {
  // Wait for the app to load and DOM to be ready
  window.addEventListener('DOMContentLoaded', () => {
    // Set up a MutationObserver to watch for conversation changes
    const observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        // If nodes are added to the DOM
        if (mutation.addedNodes.length > 0) {
          // Check if there's a conversation panel
          const conversationPanel = document.querySelector('.conversation-panel');
          if (conversationPanel) {
            // Run the fix every time message list updates
            setTimeout(() => {
              if (window.fixAllCustomCardMessages) {
                console.log('[CustomCardLoader] Auto-fixing custom cards');
                window.fixAllCustomCardMessages();
              }
            }, 500);
          }
        }
      }
    });

    // Start observing the entire document
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });

    // Also set a periodic fix every 2 seconds while viewing a conversation
    setInterval(() => {
      const conversationPanel = document.querySelector('.conversation-panel');
      if (conversationPanel && window.fixAllCustomCardMessages) {
        window.fixAllCustomCardMessages();
      }
    }, 2000);
  });
};

// Initialize the fixer
initCustomCardFixer();

export default initCustomCardFixer; 