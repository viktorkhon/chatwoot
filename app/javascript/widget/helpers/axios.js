import axios from 'axios';
import { APP_BASE_URL } from 'widget/helpers/constants';
import { getVisitorId } from './utils';

export const API = axios.create({
  baseURL: APP_BASE_URL,
  withCredentials: false,
});

// Add request interceptor to include visitor ID in headers
API.interceptors.request.use(
  config => {
    const visitorId = getVisitorId();
    
    // Add visitor ID to headers first
    if (visitorId) {
      config.headers['X-Visitor-ID'] = visitorId;
    } else {
      console.warn('[⚠️ Chatwoot Debug] No visitor ID available for request');
    }
    
    // Log after adding the header
    console.log('[🔍 Chatwoot Debug] API Request:', {
      method: config.method?.toUpperCase(),
      url: config.url,
      visitorId: visitorId,
      hasVisitorIdHeader: !!config.headers['X-Visitor-ID'],
      hasVisitorIdParam: !!(config.data?.visitor_id || config.params?.visitor_id)
    });
    
    return config;
  },
  error => {
    console.error('[❌ Chatwoot Debug] Request interceptor error:', error);
    return Promise.reject(error);
  }
);

// Add response interceptor to log API responses and errors
API.interceptors.response.use(
  response => {
    // Only log conversation_id for actual conversation-related responses
    const conversationId = response.config.url?.includes('/conversations') ? 
      (response.data?.id || response.data?.conversation_id) : 
      response.data?.conversation_id;
      
    console.log('[🔍 Chatwoot Debug] API Response:', {
      method: response.config.method?.toUpperCase(),
      url: response.config.url,
      status: response.status,
      conversationId: conversationId,
      hasData: !!response.data
    });
    return response;
  },
  error => {
    console.error('[❌ Chatwoot Debug] API Error:', {
      method: error.config?.method?.toUpperCase(),
      url: error.config?.url,
      status: error.response?.status,
      errorCode: error.response?.data?.code,
      errorMessage: error.response?.data?.error || error.message
    });
    return Promise.reject(error);
  }
);

export const setHeader = (value, key = 'X-Auth-Token') => {
  API.defaults.headers.common[key] = value;
};

export const removeHeader = key => {
  delete API.defaults.headers.common[key];
};
