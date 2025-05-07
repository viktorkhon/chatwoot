// Add this after Vue app is initialized, before or after mounting
// This makes the router available for notification navigation

// Find the section where the Vue app is created (app = createApp(...))
// and add this right after the app is mounted (app.mount(...))

// Make Vue app and router available for notification system
window.vueApp = app; // Make Vue app instance globally available
if (app && app.$router) {
  window.router = app.$router;
}

// Dispatch an event when Vue is initialized
const vueInitializedEvent = new Event('vue-initialized');
document.dispatchEvent(vueInitializedEvent); 