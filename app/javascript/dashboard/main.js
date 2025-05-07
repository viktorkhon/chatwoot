// Load user notification settings on app load
// This ensures our immediate browser notifications respect the same settings
// as Chatwoot's existing push notification system
document.addEventListener('DOMContentLoaded', () => {
  // We'll load notification settings after app is mounted
  // These will be used for our immediate tab notifications
  setTimeout(() => {
    if (window.store) {
      window.store.dispatch('userNotificationSettings/get').catch(error => {
        console.error('Error loading notification settings:', error);
      });
    }
  }, 2000);
  
  // Make sure router is accessible for cross-tab navigation
  // Use MutationObserver to detect when Vue app is mounted
  const observer = new MutationObserver((mutations) => {
    if (window.vueApp && window.vueApp.$router) {
      console.log('Router detected and set globally');
      window.router = window.vueApp.$router;
      observer.disconnect();
    }
  });
  
  // Start observing the document with configured parameters
  observer.observe(document.body, { childList: true, subtree: true });
  
  // Also try to set it immediately if already available
  if (window.vueApp && window.vueApp.$router) {
    console.log('Router detected immediately');
    window.router = window.vueApp.$router;
  }
});

// Note: We don't need to request notification permissions here
// Chatwoot already has a system for this in settings/profile/NotificationPreferences.vue 