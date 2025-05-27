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
    
    if (visitorId) {
      config.headers['X-Visitor-ID'] = visitorId;
    }
    
    return config;
  },
  error => {
    console.error('[Chatwoot] Request failed:', error.message);
    return Promise.reject(error);
  }
);

// Add response interceptor for error handling
API.interceptors.response.use(
  response => response,
  error => {
    // Only log significant errors, not routine 422s or expected failures
    if (error.response?.status >= 500) {
      console.error('[Chatwoot] Server error:', {
        url: error.config?.url,
        status: error.response?.status,
        message: error.response?.data?.error || error.message
      });
    }
    return Promise.reject(error);
  }
);

export const setHeader = (value, key = 'X-Auth-Token') => {
  API.defaults.headers.common[key] = value;
};

export const removeHeader = key => {
  delete API.defaults.headers.common[key];
};
