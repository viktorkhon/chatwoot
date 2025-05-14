import store from '../store'; // Make sure this path is correct for your project

/**
 * Sanitize HTML content to plain text for notifications
 * @param {string} htmlString - The HTML string to sanitize
 * @return {string} Plain text without HTML tags
 */
export function sanitizeContent(htmlString) {
  if (!htmlString) return '';
  // Create a temporary div to parse HTML
  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = htmlString;
  // Extract text content (removes all HTML tags)
  const textContent = tempDiv.textContent || tempDiv.innerText || '';
  // Limit length for notification
  return textContent.length > 140 ? `${textContent.substring(0, 137)}...` : textContent;
}

/**
 * Setup a broadcast channel for cross-tab communication
 * This allows us to detect if there's already a Chatwoot tab open
 */
let tabChannel;
try {
  // Only create the channel if BroadcastChannel is supported
  if (typeof BroadcastChannel !== 'undefined') {
    tabChannel = new BroadcastChannel('chatwoot-tab-communication');
    
    // Listen for tab focus requests
    tabChannel.onmessage = event => {
      console.log('BroadcastChannel message received:', event.data);
      
      if (event.data && event.data.type === 'FOCUS_REQUEST') {
        // This tab should focus and navigate to the conversation
        console.log('Focusing window from broadcast request');
        window.focus();
        
        if (event.data.conversationId) {
          const accountId = store.getters.getCurrentAccountId;
          console.log('Navigating to conversation from broadcast:', accountId, event.data.conversationId);
          
          // Respond that this tab will handle the focus request
          if (event.data.messageId) {
            tabChannel.postMessage({
              type: 'FOCUS_RESPONSE',
              messageId: event.data.messageId
            });
          }
          
          // Navigate to the conversation
          navigateWithRouter(event.data.conversationId);
        } else {
          console.warn('Missing conversationId for navigation', event.data);
        }
      }
    };
    
    // When page loads, announce this tab
    if (document.readyState === 'complete') {
      tabChannel.postMessage({ type: 'TAB_ACTIVE' });
    } else {
      window.addEventListener('load', () => {
        tabChannel.postMessage({ type: 'TAB_ACTIVE' });
      });
    }
  }
} catch (error) {
  console.error('Error setting up broadcast channel:', error);
  tabChannel = null;
}

/**
 * Navigate to a conversation or focus an existing tab
 * @param {number} conversationId - The conversation to navigate to
 */
export function navigateToConversation(conversationId) {
  // Log for debugging
  console.log('navigateToConversation called with ID:', conversationId);
  
  // Ensure conversationId is a number
  const numericConversationId = parseInt(conversationId, 10);
  
  // Track if a response has been received from another tab
  let responseReceived = false;
  
  // If we have a broadcast channel, try to focus an existing tab first
  if (tabChannel) {
    // Create a unique message ID for this request
    const messageId = `focus-${Date.now()}`;
    
    // Function to handle responses from other tabs
    const handleResponse = event => {
      if (event.data && event.data.type === 'FOCUS_RESPONSE' && event.data.messageId === messageId) {
        console.log('Received focus confirmation from another tab');
        responseReceived = true;
        // Clean up listener after receiving a response
        tabChannel.removeEventListener('message', handleResponse);
      }
    };
    
    // Listen for responses
    tabChannel.addEventListener('message', handleResponse);
    
    // Ask any open tabs to focus
    tabChannel.postMessage({ 
      type: 'FOCUS_REQUEST', 
      conversationId: numericConversationId,
      messageId
    });
    console.log('FOCUS_REQUEST sent via broadcast channel');
    
    // Set a timeout to navigate in the current tab if no other tab responds
    setTimeout(() => {
      // Remove the temporary listener
      tabChannel.removeEventListener('message', handleResponse);
      
      if (!responseReceived) {
        console.log('No response from other tabs - focusing current tab');
        // If we're here, we need to focus this tab as a fallback
        window.focus();
        
        // Try to navigate in this tab as a fallback
        navigateWithRouter(numericConversationId);
      }
    }, 500); // Increased timeout to allow for response
  } else {
    // Fallback if broadcast channel isn't supported
    console.log('No broadcast channel - focusing current tab');
    window.focus();
    navigateWithRouter(numericConversationId);
  }
}

/**
 * Helper function to navigate using the router
 * @param {number} conversationId - The conversation ID to navigate to
 * @private
 */
function navigateWithRouter(conversationId) {
  // Try multiple ways to get the router
  const routerInstance = window.router;
  
  if (routerInstance) {
    try {
      const accountId = store.getters.getCurrentAccountId;
      console.log('Navigating to conversation:', accountId, conversationId);
      
      // Ensure we're using the route name recognized by the router
      routerInstance.push({
        name: 'inbox_conversation',
        params: {
          accountId,
          conversation_id: conversationId
        }
      }).catch(error => {
        // Handle navigation errors, e.g., if already on the same route
        console.warn('Navigation warning (non-critical):', error.message);
      });
    } catch (error) {
      console.error('Router navigation error:', error);
      
      // As a last resort, try direct URL navigation
      try {
        const accountId = store.getters.getCurrentAccountId;
        const conversationUrl = `/app/accounts/${accountId}/conversations/${conversationId}`;
        console.log('Attempting direct URL navigation to:', conversationUrl);
        window.location.href = conversationUrl;
      } catch (urlError) {
        console.error('URL fallback navigation failed:', urlError);
      }
    }
  } else {
    console.error('Router not available for navigation');
    
    // Try direct URL navigation as last resort
    try {
      const accountId = store.getters.getCurrentAccountId;
      if (accountId) {
        const conversationUrl = `/app/accounts/${accountId}/conversations/${conversationId}`;
        console.log('Router unavailable, using direct URL navigation:', conversationUrl);
        window.location.href = conversationUrl;
      }
    } catch (error) {
      console.error('Direct URL navigation failed:', error);
    }
  }
}

/**
 * Show a browser notification if conditions are met (tab not focused)
 * This complements Chatwoot's existing push notification system
 * which already handles background notifications when the app is closed
 */
export function showBrowserNotification({ title, body, onClick, conversationId }) {
  try {
    // Only show if tab is not focused but browser notifications are permitted
    if (
      typeof window === 'undefined' ||
      !('Notification' in window) || 
      Notification.permission !== 'granted' ||
      !document.hidden // Only show if tab not focused
    ) {
      return null;
    }

    // Create notification
    const notification = new Notification(title, { 
      body: sanitizeContent(body),
      icon: '/assets/images/logo.png', // Add your app logo path
      tag: 'chatwoot-message' // Helps group similar notifications
    });
    
    // Default onClick handler - navigate to conversation
    if (!onClick && conversationId) {
      notification.onclick = () => {
        navigateToConversation(conversationId);
      };
    } else if (onClick && typeof onClick === 'function') {
      notification.onclick = onClick;
    }
    
    return notification;
  } catch (error) {
    console.error('Error showing notification:', error);
    return null;
  }
}

/**
 * Determine if a message should trigger a notification based on 
 * user's notification settings and conversation assignment
 */
export function shouldNotifyForMessage(messageData) {
  try {
    // Safety checks for message data structure
    if (!messageData || !messageData.conversation) {
      return false;
    }
    
    // Don't notify for agent's own messages
    if (messageData.sender_type === 'User' && 
        messageData.sender?.id === store.state?.auth?.user?.id) {
      return false;
    }
    
    const state = store.state;
    if (!state?.auth?.user) {
      return false; // No current user info
    }
    
    const currentUser = state.auth.user;
    const currentTeams = state.teams?.records || [];
    const conversation = messageData.conversation;

    // Only notify for open conversations
    if (conversation.status !== 'open') {
      return false;
    }

    // Check notification settings if available
    const notificationSettings = state.userNotificationSettings?.record;
    if (notificationSettings) {
      const pushFlags = notificationSettings.selected_push_flags || [];

      // Check if this notification type is enabled in user preferences
      if (conversation.assignee_id === currentUser.id) {
        // For assigned conversations
        return pushFlags.includes('push_assigned_conversation_new_message');
      } else if (currentTeams.some(team => team.id === conversation.team_id)) {
        // For team conversations
        return pushFlags.includes('push_assigned_conversation_new_message');
      } else {
        // For participating conversations
        return pushFlags.includes('push_participating_conversation_new_message');
      }
    }

    // If we can't check settings, default to true for assigned conversations
    return conversation.assignee_id === currentUser.id;
  } catch (error) {
    console.error('Error checking notification eligibility:', error);
    return false;
  }
}

/**
 * Request notification permission if not already granted
 * @return {Promise<string>} - The permission state
 */
export function requestNotificationPermission() {
  if (typeof window === 'undefined' || !('Notification' in window)) {
    return Promise.resolve('unsupported');
  }
  
  if (Notification.permission === 'granted') {
    // Register subscription with server if we already have permission
    navigator.serviceWorker.ready.then(registerServiceWorker);
    return Promise.resolve('granted');
  }
  
  if (Notification.permission !== 'denied') {
    return Notification.requestPermission().then(permission => {
      if (permission === 'granted') {
        // Register subscription with server if permission newly granted
        navigator.serviceWorker.ready.then(registerServiceWorker);
      }
      return permission;
    });
  }
  
  return Promise.resolve(Notification.permission);
}

/**
 * Get push subscription payload in format expected by the server
 * @param {PushSubscription} subscription - The push subscription object
 * @return {Object} Formatted payload for API
 */
export function getPushSubscriptionPayload(subscription) {
  return {
    subscription_type: 'browser_push',
    subscription_attributes: {
      endpoint: subscription.endpoint,
      p256dh: generateKeys(subscription.getKey('p256dh')),
      auth: generateKeys(subscription.getKey('auth')),
    },
  };
}

/**
 * Send registration to server
 * @param {PushSubscription} subscription - The push subscription
 * @return {Promise|null} API response or null if not authenticated
 */
export function sendRegistrationToServer(subscription) {
  if (auth.hasAuthCookie()) {
    return NotificationSubscriptions.create(
      getPushSubscriptionPayload(subscription)
    );
  }
  return null;
}

/**
 * Register the service worker for push notifications
 * @param {ServiceWorkerRegistration} registration - Service worker registration
 */
export function registerServiceWorker(registration) {
  if (!window.chatwootConfig?.vapidPublicKey) {
    console.warn('VAPID public key not available, push notifications disabled');
    return;
  }
  
  registration.pushManager
    .subscribe({
      userVisibleOnly: true,
      applicationServerKey: window.chatwootConfig.vapidPublicKey,
    })
    .then(sendRegistrationToServer)
    .then(() => {
      console.log('Push notification subscription registered with server');
    })
    .catch(error => {
      console.error('Failed to register push subscription:', error);
    });
} 