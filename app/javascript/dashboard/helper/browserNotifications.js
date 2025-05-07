import store from '../store'; // Make sure this path is correct for your project
import NotificationSubscriptions from '../api/notificationSubscriptions';
import auth from '../api/auth';

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
      if (event.data && event.data.type === 'FOCUS_REQUEST') {
        // This tab should focus and navigate to the conversation
        window.focus();
        
        if (event.data.conversationId && window.router) {
          const accountId = store.getters.getCurrentAccountId;
          window.router.push({
            name: 'inbox_conversation',
            params: {
              accountId,
              conversation_id: event.data.conversationId
            }
          });
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
  // If we have a broadcast channel, try to focus an existing tab first
  if (tabChannel) {
    // Ask any open tabs to focus
    tabChannel.postMessage({ 
      type: 'FOCUS_REQUEST', 
      conversationId 
    });
    
    // Set a small timeout - if no tab responds, we'll focus this one
    setTimeout(() => {
      // If we're here, we should focus this tab as a fallback
      window.focus();
      
      if (window.router) {
        const accountId = store.getters.getCurrentAccountId;
        window.router.push({
          name: 'inbox_conversation',
          params: {
            accountId,
            conversation_id: conversationId
          }
        });
      }
    }, 300);
  } else {
    // Fallback if broadcast channel isn't supported
    window.focus();
    
    if (window.router) {
      const accountId = store.getters.getCurrentAccountId;
      window.router.push({
        name: 'inbox_conversation',
        params: {
          accountId,
          conversation_id: conversationId
        }
      });
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