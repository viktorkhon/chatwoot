// Add this after Vue app is initialized, before or after mounting
// This makes the router available for notification navigation

// Find the section where the Vue app is created (app = createApp(...))
// and add this right after the app is mounted (app.mount(...))

/**
 * Make Vue app and router globally available for notifications
 * This should be added after app is fully initialized with router
 */
// Expose the Vue app globally for notifications to access
window.vueApp = app;

// Check if router is available and expose it
if (app && app.$router) {
  console.log('Router available, making globally accessible');
  window.router = app.$router;
} else {
  console.warn('Router not available at initialization time');
  // Try to set it when the router becomes available
  const originalPush = app.config.globalProperties.$router?.push;
  if (originalPush) {
    // Hook into router to detect when it's ready
    app.config.globalProperties.$router.push = function(...args) {
      if (!window.router) {
        console.log('Router now available, setting globally');
        window.router = app.config.globalProperties.$router;
      }
      return originalPush.apply(this, args);
    };
  }
}

// Dispatch an event when Vue is initialized
const vueInitializedEvent = new Event('vue-initialized');
document.dispatchEvent(vueInitializedEvent); 