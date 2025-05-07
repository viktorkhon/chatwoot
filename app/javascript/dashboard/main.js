// Request browser notification permission on app load
if ('Notification' in window && Notification.permission !== 'granted') {
  Notification.requestPermission();
} 

import { requestNotificationPermission } from './helper/browserNotifications';

// Request browser notification permission after app is mounted
document.addEventListener('DOMContentLoaded', () => {
  // Request permissions after a short delay to ensure app is fully loaded
  setTimeout(() => {
    requestNotificationPermission().then(permission => {
      if (permission === 'granted') {
        console.log('Browser notification permission granted');
      } else if (permission === 'denied') {
        console.warn('Browser notification permission denied');
      } else {
        console.info('Browser notification permission not determined');
      }
    });
  }, 2000);
}); 