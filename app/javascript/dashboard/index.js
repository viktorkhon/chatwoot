// Add this after Vue app is initialized, before or after mounting
// This makes the router available for notification navigation

// Dispatch an event when Vue is initialized
const vueInitializedEvent = new Event('vue-initialized');
window.vueApp = app; // Make Vue app instance globally available
document.dispatchEvent(vueInitializedEvent); 