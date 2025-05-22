import axios from 'axios';
import { APP_BASE_URL } from 'widget/helpers/constants';
import Cookies from 'js-cookie';

// Create axios instance with credentials
export const API = axios.create({
  baseURL: APP_BASE_URL,
  withCredentials: true, // Enable credentials to allow cookies to be sent
});

// Add request interceptor to include conversation cookie in requests
API.interceptors.request.use(
  config => {
    // Get the conversation cookie if it exists
    const conversationCookie = Cookies.get('cw_conversation');
    
    // If we have access to the store, prioritize that cookie (more up-to-date during navigation)
    if (window.WOOT_WIDGET?.$store?.state?.conversation?.meta?.conversationCookie) {
      const storeCookie = window.WOOT_WIDGET.$store.state.conversation.meta.conversationCookie;
      // Only add the cookie header if it's not already in the URL
      if (!config.url.includes('cw_conversation=') && storeCookie) {
        // Add as custom header to ensure it's passed
        config.headers['X-Chatwoot-Conversation'] = storeCookie;
      }
    } 
    // Fallback to the actual cookie
    else if (conversationCookie && !config.url.includes('cw_conversation=')) {
      config.headers['X-Chatwoot-Conversation'] = conversationCookie;
    }
    
    return config;
  },
  error => Promise.reject(error)
);

export const setHeader = (value, key = 'X-Auth-Token') => {
  API.defaults.headers.common[key] = value;
};

export const removeHeader = key => {
  delete API.defaults.headers.common[key];
};
