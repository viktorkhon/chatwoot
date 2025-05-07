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
 * Show a browser notification if conditions are met
 * @param {Object} options - Notification options
 * @param {string} options.title - Notification title
 * @param {string} options.body - Notification body
 * @param {Function} options.onClick - Callback when notification is clicked
 * @return {Notification|null} The notification object or null if not shown
 */
export function showBrowserNotification({ title, body, onClick }) {
  try {
    // Check if notifications are available and permitted
    if (
      typeof window === 'undefined' ||
      !('Notification' in window) || 
      Notification.permission !== 'granted' ||
      !document.hidden // Only show if tab not focused
    ) {
      return null;
    }

    // Sanitize the body text if it contains HTML
    const sanitizedBody = sanitizeContent(body);
    
    // Create notification
    const notification = new Notification(title, { 
      body: sanitizedBody,
      icon: '/assets/images/logo.png', // Add your app logo path
      tag: 'chatwoot-message' // Helps group similar notifications
    });
    
    // Add click handler if provided
    if (onClick && typeof onClick === 'function') {
      notification.onclick = onClick;
    }
    
    return notification;
  } catch (error) {
    console.error('Error showing notification:', error);
    return null;
  }
}

/**
 * Determine if a message should trigger a notification
 * @param {Object} messageData - The message data from ActionCable
 * @return {boolean} Whether to notify for this message
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

    // Assigned to agent
    if (
      conversation.assignee_id &&
      conversation.assignee_id === currentUser.id
    ) {
      return true;
    }

    // Assigned to a team the agent is in
    if (
      conversation.team_id &&
      currentTeams.some(team => team.id === conversation.team_id)
    ) {
      return true;
    }

    return false;
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
    return Promise.resolve('granted');
  }
  
  if (Notification.permission !== 'denied') {
    return Notification.requestPermission();
  }
  
  return Promise.resolve(Notification.permission);
} 