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
  document.addEventListener('vue-initialized', () => {
    if (window.vueApp && window.vueApp.$router) {
      window.router = window.vueApp.$router;
    }
  });
});

// Note: We don't need to request notification permissions here
// Chatwoot already has a system for this in settings/profile/NotificationPreferences.vue 